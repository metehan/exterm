// Initialize the terminal
const terminal = new Terminal({
    cursorBlink: true,
    theme: {
        background: '#1e1e1e',
        foreground: '#ffffff'
    },
    fontFamily: 'Courier New, monospace',
    fontSize: 14
});

// Open WebSocket connection
const socket = new WebSocket('ws://localhost:4000/ws');

// Attach terminal to the DOM
terminal.open(document.getElementById('terminal'));

// Focus the terminal immediately
terminal.focus();

// Handle WebSocket connection
socket.onopen = () => {
    // terminal.write('Connected to shell...\r\n');
    // Focus the terminal when connected
    terminal.focus();
    // Send initial newline to get the prompt
    //socket.send('neofetch\n');

    // Set up client-side keepalive (send a space and backspace every 5 minutes as fallback)
    setInterval(() => {
        if (socket.readyState === WebSocket.OPEN) {
            // Send invisible keepalive (null character that won't affect terminal)
            socket.send('\x00');
        }
    }, 5 * 60 * 1000); // Every 5 minutes
};

socket.onmessage = (event) => {
    // Handle ping frames (though most browsers handle this automatically)
    if (event.data === '') {
        // This is likely a ping, browsers usually handle pong automatically
        return;
    }
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
    console.log('Sending data:', JSON.stringify(data)); // Debug log
    if (socket.readyState === WebSocket.OPEN) {
        socket.send(data);
    }
});

// Ensure terminal stays focused when clicked
document.getElementById('terminal').addEventListener('click', () => {
    terminal.focus();
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