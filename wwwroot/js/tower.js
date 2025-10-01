(() => {
    const lane = document.getElementById('towerLane');
    if (!lane) {
        return;
    }

    const gateNames = ['And', 'Or', 'Xor', 'NotA', 'NotB'];
    const targets = ['A AND B', 'A OR B', 'A XOR B', 'A NAND B', 'A NOR B', 'A XNOR B', 'NOT A', 'NOT B'];
    const palette = document.getElementById('towerPalette');
    const startBtn = document.getElementById('towerStartBtn');
    const pauseBtn = document.getElementById('towerPauseBtn');
    const resetBtn = document.getElementById('towerResetBtn');
    const speedSelect = document.getElementById('towerSpeed');
    const waveLabel = document.getElementById('towerWave');
    const hpLabel = document.getElementById('towerHp');
    const scoreLabel = document.getElementById('towerScore');
    const enemiesLabel = document.getElementById('towerEnemies');

    function createRng(seed) {
        let value = seed % 2147483647;
        if (value <= 0) value += 2147483646;
        return () => {
            value = value * 16807 % 2147483647;
            return (value - 1) / 2147483646;
        };
    }

    const state = {
        towers: new Array(5).fill(null),
        selectedGate: null,
        enemies: [],
        wave: 1,
        hp: 5,
        score: 0,
        running: false,
        timer: null,
        spawnCooldown: 0,
        defeated: 0,
        rng: createRng(1)
    };

    function createLane() {
        lane.innerHTML = '';
        state.towers.forEach((gate, index) => {
            const cell = document.createElement('button');
            cell.className = 'tower-cell btn btn-outline-primary';
            cell.setAttribute('type', 'button');
            cell.dataset.index = index;
            cell.textContent = gate ? gate : 'Empty';
            cell.addEventListener('click', () => {
                if (state.selectedGate) {
                    state.towers[index] = state.selectedGate;
                    renderLane();
                }
            });
            lane.appendChild(cell);
        });
    }

    function renderLane() {
        const cells = lane.querySelectorAll('.tower-cell');
        cells.forEach(cell => {
            const index = Number(cell.dataset.index);
            cell.textContent = state.towers[index] ? state.towers[index] : 'Empty';
        });
    }

    function renderPalette() {
        palette.innerHTML = '';
        gateNames.forEach(name => {
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.className = 'btn btn-sm btn-outline-dark';
            btn.textContent = name;
            btn.addEventListener('click', () => {
                state.selectedGate = name;
                Array.from(palette.children).forEach(child => child.classList.remove('active'));
                btn.classList.add('active');
            });
            palette.appendChild(btn);
        });
    }

    function updateLabels() {
        waveLabel.textContent = state.wave.toString();
        hpLabel.textContent = state.hp.toString();
        scoreLabel.textContent = state.score.toString();
        enemiesLabel.textContent = state.enemies.length.toString();
    }

    function spawnEnemy() {
        const a = state.rng() >= 0.5;
        const b = state.rng() >= 0.5;
        const targetIndex = Math.floor(state.rng() * Math.min(targets.length, 2 + state.wave));
        const target = targets[targetIndex];
        state.enemies.push({ position: -1, a, b, target, resolved: false });
        updateLabels();
    }

    function evaluateGate(gate, a, b) {
        switch (gate) {
            case 'And': return a && b;
            case 'Or': return a || b;
            case 'Xor': return a !== b;
            case 'NotA': return !a;
            case 'NotB': return !b;
            default: return false;
        }
    }

    function evaluateTarget(target, a, b) {
        switch (target) {
            case 'A AND B': return a && b;
            case 'A OR B': return a || b;
            case 'A XOR B': return a !== b;
            case 'A NAND B': return !(a && b);
            case 'A NOR B': return !(a || b);
            case 'A XNOR B': return a === b;
            case 'NOT A': return !a;
            case 'NOT B': return !b;
            default: return false;
        }
    }

    function tick() {
        if (!state.running) {
            return;
        }

        const speed = Number(speedSelect.value);
        state.spawnCooldown -= 0.05 * speed;
        if (state.spawnCooldown <= 0) {
            spawnEnemy();
            state.spawnCooldown = Math.max(1.5 - state.wave * 0.1, 0.6);
        }

        state.enemies.forEach(enemy => {
            if (enemy.resolved) {
                return;
            }
            enemy.position += 0.2 * speed;
            const index = Math.floor(enemy.position);
            if (index >= 0 && index < state.towers.length && !enemy.resolved) {
                const towerGate = state.towers[index];
                if (towerGate) {
                    const gateResult = evaluateGate(towerGate, enemy.a, enemy.b);
                    const targetResult = evaluateTarget(enemy.target, enemy.a, enemy.b);
                    enemy.resolved = true;
                    if (gateResult === targetResult) {
                        state.score += 50;
                        state.defeated += 1;
                    } else {
                        state.score -= 25;
                        state.hp = Math.max(0, state.hp - 1);
                    }
                }
            }
            if (enemy.position >= state.towers.length && !enemy.resolved) {
                enemy.resolved = true;
                state.hp = Math.max(0, state.hp - 1);
            }
        });

        state.enemies = state.enemies.filter(e => !e.resolved || e.position < state.towers.length + 1);
        if (state.hp <= 0) {
            endWave(false);
        } else if (state.defeated >= 10) {
            endWave(true);
        }

        updateLabels();
    }

    function startWave() {
        if (state.hp <= 0) {
            state.hp = 5;
        }
        state.running = true;
        state.spawnCooldown = 0;
        state.enemies = [];
        state.defeated = 0;
        state.rng = createRng(state.wave * 7919);
        if (state.timer) {
            clearInterval(state.timer);
        }
        state.timer = setInterval(tick, 100);
        pauseBtn.textContent = 'Pause';
        updateLabels();
    }

    function pauseWave() {
        state.running = !state.running;
        pauseBtn.textContent = state.running ? 'Pause' : 'Resume';
    }

    function resetWave() {
        state.wave = 1;
        state.hp = 5;
        state.score = 0;
        state.towers = new Array(5).fill(null);
        state.running = false;
        state.enemies = [];
        state.defeated = 0;
        state.rng = createRng(1);
        if (state.timer) {
            clearInterval(state.timer);
        }
        renderLane();
        pauseBtn.textContent = 'Pause';
        updateLabels();
    }

    async function endWave(success) {
        state.running = false;
        if (state.timer) {
            clearInterval(state.timer);
        }
        if (success) {
            state.score += state.wave * 25;
            await window.AlgoPlayground.postScore({
                gameId: 'TowerLogic',
                level: state.wave,
                points: Math.max(0, state.score),
                durationSec: state.wave * 30
            });
            state.wave += 1;
            state.hp = Math.min(10, state.hp + 1);
        }
        state.enemies = [];
        state.defeated = 0;
        updateLabels();
    }

    createLane();
    renderPalette();
    updateLabels();

    startBtn.addEventListener('click', startWave);
    pauseBtn.addEventListener('click', pauseWave);
    resetBtn.addEventListener('click', resetWave);
})();
