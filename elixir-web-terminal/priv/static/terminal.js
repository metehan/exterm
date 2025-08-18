// Initialize the terminal
const terminal = new Terminal({
    cursorBlink: true,
    theme: {
        background: '#1e1e1e',
        foreground: '#ffffff'
    }
});

// Open WebSocket connection
const socket = new WebSocket('ws://localhost:4000/ws');

// Attach terminal to the DOM
terminal.open(document.getElementById('terminal'));

// Handle WebSocket connection
socket.onopen = () => {
    terminal.write('Connected to shell...\r\n');
    // Send initial newline to get the prompt
    socket.send('\n');
};

socket.onmessage = (event) => {
    terminal.write(event.data);
};

socket.onclose = () => {
    terminal.write('\r\nConnection closed.\r\n');
};

socket.onerror = (error) => {
    terminal.write('\r\nConnection error: ' + error + '\r\n');
};

// Send terminal input to WebSocket
terminal.onData(data => {
    if (socket.readyState === WebSocket.OPEN) {
        socket.send(data);
    }
});

// Handle terminal resize
function resizeTerminal() {
    const container = document.getElementById('terminal');
    const rect = container.getBoundingClientRect();
    const cols = Math.floor(rect.width / 9); // Approximate character width
    const rows = Math.floor(rect.height / 17); // Approximate character height
    terminal.resize(cols, rows);
}

// Resize terminal on window resize
window.addEventListener('resize', resizeTerminal);

// Initial resize
setTimeout(resizeTerminal, 100);