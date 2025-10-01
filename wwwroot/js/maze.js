(() => {
    const canvas = document.getElementById('mazeCanvas');
    if (!canvas) {
        return;
    }

    const ctx = canvas.getContext('2d');
    const stepsLabel = document.getElementById('mazeSteps');
    const timerLabel = document.getElementById('mazeTimer');
    const levelLabel = document.getElementById('mazeLevel');
    const optimalLabel = document.getElementById('mazeOptimal');
    const nodesLabel = document.getElementById('mazeNodes');
    const scoreLabel = document.getElementById('mazeScore');
    const startBtn = document.getElementById('mazeStartBtn');
    const pauseBtn = document.getElementById('mazePauseBtn');
    const resetBtn = document.getElementById('mazeResetBtn');
    const nextBtn = document.getElementById('mazeNextBtn');

    const state = {
        level: 1,
        gridSize: 7,
        grid: [],
        start: { row: 0, col: 0 },
        goal: { row: 0, col: 0 },
        player: { row: 0, col: 0 },
        steps: 0,
        elapsed: 0,
        timer: null,
        running: false,
        finished: false
    };

    function createRng(seed) {
        let value = seed % 2147483647;
        if (value <= 0) value += 2147483646;
        return () => {
            value = value * 16807 % 2147483647;
            return (value - 1) / 2147483646;
        };
    }

    function hasPath(grid, start, goal) {
        const size = grid.length;
        const queue = [[start.row, start.col]];
        const visited = Array.from({ length: size }, () => Array(size).fill(false));
        visited[start.row][start.col] = true;
        const directions = [[1,0],[-1,0],[0,1],[0,-1]];
        while (queue.length > 0) {
            const [r, c] = queue.shift();
            if (r === goal.row && c === goal.col) {
                return true;
            }
            for (const [dr, dc] of directions) {
                const nr = r + dr;
                const nc = c + dc;
                if (nr < 0 || nc < 0 || nr >= size || nc >= size) continue;
                if (visited[nr][nc] || grid[nr][nc] === 0) continue;
                visited[nr][nc] = true;
                queue.push([nr, nc]);
            }
        }
        return false;
    }

    function generateGrid() {
        const size = 6 + state.level;
        state.gridSize = size;
        const rng = createRng(state.level * 9973);
        let attempts = 0;
        do {
            state.grid = Array.from({ length: size }, (_, r) => Array.from({ length: size }, (_, c) => {
                if ((r === 0 && c === 0) || (r === size - 1 && c === size - 1)) {
                    return 1;
                }
                return rng() > 0.22 ? 1 : 0;
            }));
            attempts++;
        } while (!hasPath(state.grid, { row: 0, col: 0 }, { row: size - 1, col: size - 1 }) && attempts < 10);

        if (!hasPath(state.grid, { row: 0, col: 0 }, { row: size - 1, col: size - 1 })) {
            state.grid = Array.from({ length: size }, () => Array(size).fill(1));
        }

        state.start = { row: 0, col: 0 };
        state.goal = { row: size - 1, col: size - 1 };
        state.player = { ...state.start };
        state.steps = 0;
        state.elapsed = 0;
        state.finished = false;
        optimalLabel.textContent = '-';
        nodesLabel.textContent = '-';
        scoreLabel.textContent = '-';
        updateLabels();
        draw();
    }

    function updateLabels() {
        stepsLabel.textContent = state.steps.toString();
        timerLabel.textContent = `${state.elapsed}s`;
        levelLabel.textContent = state.level.toString();
    }

    function startTimer() {
        if (state.timer) {
            clearInterval(state.timer);
        }
        state.timer = setInterval(() => {
            if (state.running) {
                state.elapsed += 1;
                updateLabels();
            }
        }, 1000);
    }

    function draw(path = []) {
        const size = state.gridSize;
        const cellSize = canvas.width / size;
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        for (let r = 0; r < size; r++) {
            for (let c = 0; c < size; c++) {
                ctx.fillStyle = state.grid[r][c] === 1 ? '#ffffff' : '#1f2933';
                ctx.fillRect(c * cellSize, r * cellSize, cellSize, cellSize);
                ctx.strokeStyle = '#d1d5db';
                ctx.strokeRect(c * cellSize, r * cellSize, cellSize, cellSize);
            }
        }

        ctx.fillStyle = '#10b981';
        ctx.fillRect(state.start.col * cellSize, state.start.row * cellSize, cellSize, cellSize);
        ctx.fillStyle = '#3b82f6';
        ctx.fillRect(state.goal.col * cellSize, state.goal.row * cellSize, cellSize, cellSize);

        if (path.length > 0) {
            ctx.fillStyle = 'rgba(59,130,246,0.3)';
            for (const node of path) {
                ctx.fillRect(node.col * cellSize, node.row * cellSize, cellSize, cellSize);
            }
        }

        ctx.fillStyle = '#ef4444';
        ctx.fillRect(state.player.col * cellSize + cellSize * 0.2, state.player.row * cellSize + cellSize * 0.2, cellSize * 0.6, cellSize * 0.6);
    }

    async function finishLevel() {
        state.running = false;
        state.finished = true;
        if (state.timer) {
            clearInterval(state.timer);
        }

        const payload = {
            grid: state.grid.map(row => row.map(cell => cell ? 1 : 0)),
            start: state.start,
            goal: state.goal
        };

        try {
            const response = await fetch('/Game/MazeRunner/Api?handler=ComputeBfs', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (!response.ok) {
                throw new Error('BFS failed');
            }
            const result = await response.json();
            optimalLabel.textContent = result.optimal;
            nodesLabel.textContent = result.nodesExpanded;
            draw(result.path || []);
            const score = Math.max(0, Math.round(1000 - 10 * (state.steps - result.optimal) - 2 * state.elapsed));
            scoreLabel.textContent = score.toString();
            await window.AlgoPlayground.postScore({
                gameId: 'MazeRunner',
                level: state.level,
                points: score,
                durationSec: state.elapsed
            });
        } catch (err) {
            console.error(err);
        }
    }

    function handleMove(rowDelta, colDelta) {
        if (!state.running || state.finished) {
            return;
        }
        const nextRow = state.player.row + rowDelta;
        const nextCol = state.player.col + colDelta;
        if (nextRow < 0 || nextCol < 0 || nextRow >= state.gridSize || nextCol >= state.gridSize) {
            return;
        }
        if (state.grid[nextRow][nextCol] === 0) {
            return;
        }
        state.player = { row: nextRow, col: nextCol };
        state.steps += 1;
        updateLabels();
        draw();
        if (state.player.row === state.goal.row && state.player.col === state.goal.col) {
            finishLevel();
        }
    }

    function onKeyDown(event) {
        const key = event.key.toLowerCase();
        if (['arrowup', 'w'].includes(key)) {
            handleMove(-1, 0);
        } else if (['arrowdown', 's'].includes(key)) {
            handleMove(1, 0);
        } else if (['arrowleft', 'a'].includes(key)) {
            handleMove(0, -1);
        } else if (['arrowright', 'd'].includes(key)) {
            handleMove(0, 1);
        }
    }

    function startGame() {
        state.running = true;
        pauseBtn.textContent = 'Pause';
        state.finished = false;
        updateLabels();
        startTimer();
        canvas.focus();
    }

    function pauseGame() {
        state.running = !state.running;
        pauseBtn.textContent = state.running ? 'Pause' : 'Resume';
    }

    function resetGame() {
        generateGrid();
        state.running = false;
        pauseBtn.textContent = 'Pause';
        if (state.timer) {
            clearInterval(state.timer);
        }
        timerLabel.textContent = '0s';
        stepsLabel.textContent = '0';
    }

    function nextLevel() {
        state.level += 1;
        generateGrid();
        startGame();
    }

    document.addEventListener('keydown', onKeyDown);
    startBtn.addEventListener('click', startGame);
    pauseBtn.addEventListener('click', pauseGame);
    resetBtn.addEventListener('click', resetGame);
    nextBtn.addEventListener('click', nextLevel);

    generateGrid();
})();
