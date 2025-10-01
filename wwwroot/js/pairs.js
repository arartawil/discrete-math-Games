(() => {
    const domainContainer = document.getElementById('pairsDomain');
    if (!domainContainer) {
        return;
    }

    const codomainContainer = document.getElementById('pairsCodomain');
    const listContainer = document.getElementById('pairsList');
    const modeSelect = document.getElementById('pairsMode');
    const startBtn = document.getElementById('pairsStartBtn');
    const resetBtn = document.getElementById('pairsResetBtn');
    const levelLabel = document.getElementById('pairsLevel');
    const timerLabel = document.getElementById('pairsTimer');
    const attemptsLabel = document.getElementById('pairsAttempts');
    const validLabel = document.getElementById('pairsValid');
    const accuracyLabel = document.getElementById('pairsAccuracy');
    const scoreLabel = document.getElementById('pairsScore');

    const state = {
        level: 1,
        duration: 60,
        remaining: 60,
        timer: null,
        running: false,
        attempts: 0,
        valid: 0,
        pairs: [],
        selectedDomain: null,
        selectedCodomain: null
    };

    function generateSets() {
        const size = 3 + Math.min(2, state.level);
        const domain = Array.from({ length: size }, (_, i) => `d${i + 1}`);
        const codomain = Array.from({ length: size + 1 }, (_, i) => `c${i + 1}`);
        renderSet(domainContainer, domain, 'domain');
        renderSet(codomainContainer, codomain, 'codomain');
        state.pairs = [];
        updateList();
    }

    function renderSet(container, items, type) {
        container.innerHTML = '';
        container.style.gridTemplateColumns = `repeat(${Math.min(items.length, 3)}, minmax(0, 1fr))`;
        items.forEach(item => {
            const button = document.createElement('button');
            button.type = 'button';
            button.className = 'btn btn-outline-primary';
            button.textContent = item;
            button.dataset.item = item;
            button.addEventListener('click', () => handleSelection(type, item, button));
            container.appendChild(button);
        });
    }

    function handleSelection(type, item, button) {
        if (!state.running) {
            return;
        }
        if (type === 'domain') {
            state.selectedDomain = item;
            Array.from(domainContainer.children).forEach(c => c.classList.remove('active'));
            button.classList.add('active');
        } else {
            state.selectedCodomain = item;
            Array.from(codomainContainer.children).forEach(c => c.classList.remove('active'));
            button.classList.add('active');
        }
        if (state.selectedDomain && state.selectedCodomain) {
            evaluatePair(state.selectedDomain, state.selectedCodomain);
            state.selectedDomain = null;
            state.selectedCodomain = null;
            Array.from(domainContainer.children).forEach(c => c.classList.remove('active'));
            Array.from(codomainContainer.children).forEach(c => c.classList.remove('active'));
        }
    }

    function evaluatePair(domain, codomain) {
        state.attempts += 1;
        const existing = state.pairs.find(p => p.domain === domain);
        const isFunctionMode = modeSelect.value === 'function';
        let valid = true;
        if (existing && existing.codomain !== codomain && isFunctionMode) {
            valid = false;
        }
        if (valid) {
            if (existing) {
                existing.codomain = codomain;
            } else {
                state.pairs.push({ domain, codomain });
            }
            state.valid += 1;
        }
        updateList();
        updateLabels();
    }

    function updateList() {
        listContainer.innerHTML = '';
        if (state.pairs.length === 0) {
            const empty = document.createElement('li');
            empty.className = 'list-group-item text-muted';
            empty.textContent = 'No pairs created yet.';
            listContainer.appendChild(empty);
            return;
        }
        state.pairs.forEach(pair => {
            const item = document.createElement('li');
            item.className = 'list-group-item d-flex justify-content-between align-items-center';
            item.textContent = `(${pair.domain}, ${pair.codomain})`;
            listContainer.appendChild(item);
        });
    }

    function updateLabels() {
        attemptsLabel.textContent = state.attempts.toString();
        validLabel.textContent = state.valid.toString();
        const accuracy = state.attempts === 0 ? 0 : Math.round((state.valid / state.attempts) * 100);
        accuracyLabel.textContent = `${accuracy}%`;
        timerLabel.textContent = `${state.remaining}s`;
        levelLabel.textContent = state.level.toString();
    }

    function startRound() {
        state.running = true;
        state.remaining = state.duration;
        state.attempts = 0;
        state.valid = 0;
        state.pairs = [];
        updateList();
        updateLabels();
        if (state.timer) {
            clearInterval(state.timer);
        }
        state.timer = setInterval(() => {
            if (!state.running) {
                return;
            }
            state.remaining -= 1;
            if (state.remaining <= 0) {
                finishRound();
            }
            updateLabels();
        }, 1000);
    }

    function resetRound() {
        state.level = 1;
        state.running = false;
        state.remaining = state.duration;
        state.attempts = 0;
        state.valid = 0;
        state.pairs = [];
        if (state.timer) {
            clearInterval(state.timer);
        }
        generateSets();
        updateLabels();
        scoreLabel.textContent = '0';
    }

    async function finishRound() {
        state.running = false;
        if (state.timer) {
            clearInterval(state.timer);
        }
        const penalty = Math.max(0, state.attempts - state.valid);
        const score = Math.max(0, state.valid * 20 - penalty * 5 + state.remaining * 2);
        scoreLabel.textContent = score.toString();
        await window.AlgoPlayground.postScore({
            gameId: 'MatchingPairs',
            level: state.level,
            points: score,
            durationSec: state.duration - state.remaining
        });
        state.level += 1;
        generateSets();
        updateLabels();
    }

    generateSets();
    updateLabels();

    startBtn.addEventListener('click', startRound);
    resetBtn.addEventListener('click', resetRound);
})();
