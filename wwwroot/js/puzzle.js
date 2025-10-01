(() => {
    const grid = document.getElementById('puzzleGrid');
    if (!grid) {
        return;
    }

    const levelLabel = document.getElementById('puzzleLevel');
    const movesLabel = document.getElementById('puzzleMoves');
    const timerLabel = document.getElementById('puzzleTimer');
    const inversionsLabel = document.getElementById('puzzleInversions');
    const manhattanLabel = document.getElementById('puzzleManhattan');
    const scoreLabel = document.getElementById('puzzleScore');
    const hintText = document.getElementById('puzzleHintText');
    const startBtn = document.getElementById('puzzleStartBtn');
    const hintBtn = document.getElementById('puzzleHintBtn');
    const resetBtn = document.getElementById('puzzleResetBtn');
    const nextBtn = document.getElementById('puzzleNextBtn');

    function createRng(seed) {
        let value = seed % 2147483647;
        if (value <= 0) value += 2147483646;
        return () => {
            value = value * 16807 % 2147483647;
            return (value - 1) / 2147483646;
        };
    }

    const state = {
        level: 1,
        dimension: 3,
        tiles: [],
        moves: 0,
        elapsed: 0,
        timer: null,
        running: false,
        rng: createRng(1)
    };

    function dimensionForLevel(level) {
        return level < 2 ? 3 : 4;
    }

    function createSolvedTiles() {
        const size = state.dimension * state.dimension;
        return Array.from({ length: size }, (_, i) => (i + 1) % size);
    }

    function shuffleTiles() {
        const tiles = createSolvedTiles();
        let blankIndex = tiles.length - 1;
        const moves = state.dimension * state.dimension * 20;
        for (let i = 0; i < moves; i++) {
            const neighbors = getNeighbors(blankIndex);
            const swapIndex = neighbors[Math.floor(state.rng() * neighbors.length)];
            [tiles[blankIndex], tiles[swapIndex]] = [tiles[swapIndex], tiles[blankIndex]];
            blankIndex = swapIndex;
        }
        if (!isSolvable(tiles)) {
            const a = tiles[0] === 0 ? 1 : 0;
            const b = tiles[1] === 0 ? 2 : 1;
            [tiles[a], tiles[b]] = [tiles[b], tiles[a]];
        }
        return tiles;
    }

    function renderTiles() {
        grid.innerHTML = '';
        grid.style.gridTemplateColumns = `repeat(${state.dimension}, minmax(0, 1fr))`;
        state.tiles.forEach((value, index) => {
            const tile = document.createElement('button');
            tile.type = 'button';
            tile.className = value === 0 ? 'puzzle-tile puzzle-empty' : 'puzzle-tile';
            tile.textContent = value === 0 ? '' : value.toString();
            tile.dataset.index = index.toString();
            tile.addEventListener('click', () => moveTile(index));
            grid.appendChild(tile);
        });
    }

    function getNeighbors(index) {
        const row = Math.floor(index / state.dimension);
        const col = index % state.dimension;
        const neighbors = [];
        if (row > 0) neighbors.push(index - state.dimension);
        if (row < state.dimension - 1) neighbors.push(index + state.dimension);
        if (col > 0) neighbors.push(index - 1);
        if (col < state.dimension - 1) neighbors.push(index + 1);
        return neighbors;
    }

    function moveTile(index) {
        if (!state.running) {
            return;
        }
        const blankIndex = state.tiles.indexOf(0);
        if (!getNeighbors(blankIndex).includes(index)) {
            return;
        }
        [state.tiles[blankIndex], state.tiles[index]] = [state.tiles[index], state.tiles[blankIndex]];
        state.moves += 1;
        movesLabel.textContent = state.moves.toString();
        renderTiles();
        if (isSolved()) {
            finishPuzzle();
        }
    }

    function isSolved() {
        for (let i = 0; i < state.tiles.length - 1; i++) {
            if (state.tiles[i] !== i + 1) {
                return false;
            }
        }
        return state.tiles[state.tiles.length - 1] === 0;
    }

    function startTimer() {
        if (state.timer) {
            clearInterval(state.timer);
        }
        state.timer = setInterval(() => {
            if (state.running) {
                state.elapsed += 1;
                timerLabel.textContent = `${state.elapsed}s`;
            }
        }, 1000);
    }

    function updateStats() {
        movesLabel.textContent = state.moves.toString();
        timerLabel.textContent = `${state.elapsed}s`;
        levelLabel.textContent = state.level.toString();
    }

    function startPuzzle() {
        state.running = true;
        state.elapsed = 0;
        state.moves = 0;
        state.dimension = dimensionForLevel(state.level);
        state.rng = createRng(state.level * 4567);
        state.tiles = shuffleTiles();
        renderTiles();
        updateStats();
        scoreLabel.textContent = '-';
        hintText.textContent = 'Press Hint to compute heuristics.';
        startTimer();
    }

    function resetPuzzle() {
        state.level = 1;
        state.dimension = dimensionForLevel(state.level);
        state.tiles = createSolvedTiles();
        state.running = false;
        state.rng = createRng(1);
        state.elapsed = 0;
        state.moves = 0;
        renderTiles();
        updateStats();
        inversionsLabel.textContent = '-';
        manhattanLabel.textContent = '-';
        scoreLabel.textContent = '-';
        hintText.textContent = 'Press Hint to compute heuristics.';
        if (state.timer) {
            clearInterval(state.timer);
        }
    }

    function nextLevel() {
        state.level += 1;
        levelLabel.textContent = state.level.toString();
        startPuzzle();
    }

    function countInversions(tiles) {
        let count = 0;
        for (let i = 0; i < tiles.length; i++) {
            if (tiles[i] === 0) continue;
            for (let j = i + 1; j < tiles.length; j++) {
                if (tiles[j] === 0) continue;
                if (tiles[i] > tiles[j]) count++;
            }
        }
        return count;
    }

    function manhattanDistance(tiles) {
        let distance = 0;
        tiles.forEach((value, index) => {
            if (value === 0) return;
            const currentRow = Math.floor(index / state.dimension);
            const currentCol = index % state.dimension;
            const targetRow = Math.floor((value - 1) / state.dimension);
            const targetCol = (value - 1) % state.dimension;
            distance += Math.abs(currentRow - targetRow) + Math.abs(currentCol - targetCol);
        });
        return distance;
    }

    function isSolvable(tiles) {
        const inversions = countInversions(tiles);
        if (state.dimension % 2 === 1) {
            return inversions % 2 === 0;
        }
        const blankRow = Math.floor(tiles.indexOf(0) / state.dimension);
        const rowFromBottom = state.dimension - blankRow;
        return rowFromBottom % 2 === 0 ? inversions % 2 === 1 : inversions % 2 === 0;
    }

    function hint() {
        const inversions = countInversions(state.tiles);
        const manhattan = manhattanDistance(state.tiles);
        inversionsLabel.textContent = inversions.toString();
        manhattanLabel.textContent = manhattan.toString();
        hintText.textContent = `Lower bound: ${manhattan} moves. Inversions: ${inversions}.`;
    }

    async function finishPuzzle() {
        state.running = false;
        if (state.timer) {
            clearInterval(state.timer);
        }
        const inversions = countInversions(state.tiles);
        const manhattan = manhattanDistance(state.tiles);
        const score = Math.max(0, Math.round(1500 - 5 * state.moves - 2 * state.elapsed + Math.max(0, 50 - inversions)));
        scoreLabel.textContent = score.toString();
        await window.AlgoPlayground.postScore({
            gameId: 'PuzzleSolver',
            level: state.level,
            points: score,
            durationSec: state.elapsed
        });
        inversionsLabel.textContent = inversions.toString();
        manhattanLabel.textContent = manhattan.toString();
    }

    startBtn.addEventListener('click', startPuzzle);
    hintBtn.addEventListener('click', hint);
    resetBtn.addEventListener('click', resetPuzzle);
    nextBtn.addEventListener('click', nextLevel);

    resetPuzzle();
})();
