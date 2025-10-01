window.AlgoPlayground = window.AlgoPlayground || {};

window.AlgoPlayground.postScore = async function (payload) {
    const response = await fetch('/Scores?handler=Add', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
    });

    if (!response.ok) {
        console.warn('Failed to persist score', await response.text());
        return null;
    }

    return await response.json();
};

window.AlgoPlayground.formatTime = function (seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return mins > 0 ? `${mins}m ${secs}s` : `${secs}s`;
};
