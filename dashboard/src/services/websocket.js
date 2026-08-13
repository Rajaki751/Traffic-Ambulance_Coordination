const WS_BASE = import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:8000';

export function connectAdminWebSocket(token, onMessage) {
  const url = `${WS_BASE}/ws/live?token=${encodeURIComponent(token)}&channel=admin`;
  const ws = new WebSocket(url);

  ws.onopen = () => console.log('WebSocket connected');
  ws.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      onMessage(data);
    } catch (e) {
      console.error('WS parse error', e);
    }
  };
  ws.onerror = (err) => console.error('WebSocket error', err);
  ws.onclose = () => console.log('WebSocket closed');

  const pingInterval = setInterval(() => {
    if (ws.readyState === WebSocket.OPEN) ws.send('ping');
  }, 30000);

  return () => {
    clearInterval(pingInterval);
    ws.close();
  };
}
