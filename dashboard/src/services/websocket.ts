const WS_BASE = import.meta.env.VITE_WS_BASE_URL || 'ws://localhost:8000';

const INITIAL_RETRY_MS = 1000;
const MAX_RETRY_MS = 30000;

export function connectAdminWebSocket(token: string, onMessage: (msg: any) => void, { onStatusChange, onSessionExpired }: { onStatusChange?: (status: string) => void; onSessionExpired?: () => void } = {}) {
  const url = `${WS_BASE}/ws/live?token=${encodeURIComponent(token)}&channel=admin`;
  let ws = null;
  let pingInterval = null;
  let retryTimer = null;
  let retryCount = 0;
  let manuallyClosed = false;

  const clearPing = () => {
    if (pingInterval) {
      clearInterval(pingInterval);
      pingInterval = null;
    }
  };

  const connect = () => {
    onStatusChange?.('connecting');
    ws = new WebSocket(url);

    ws.onopen = () => {
      retryCount = 0;
      clearPing();
      pingInterval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) ws.send('ping');
      }, 30000);
      onStatusChange?.('open');
    };

    ws.onmessage = (event) => {
      try {
        onMessage(JSON.parse(event.data));
      } catch (e) {
        console.error('WS parse error', e);
      }
    };

    ws.onclose = (event) => {
      clearPing();
      if (manuallyClosed) {
        onStatusChange?.('closed');
        return;
      }
      if (event.code === 1008) {
        onStatusChange?.('closed');
        onSessionExpired?.();
        return;
      }
      onStatusChange?.('reconnecting');
      const delay = Math.min(INITIAL_RETRY_MS * 2 ** retryCount, MAX_RETRY_MS);
      retryCount += 1;
      retryTimer = setTimeout(connect, delay);
    };
  };

  connect();

  return () => {
    manuallyClosed = true;
    clearPing();
    if (retryTimer) clearTimeout(retryTimer);
    if (ws && (ws.readyState === WebSocket.OPEN || ws.readyState === WebSocket.CONNECTING)) {
      ws.close();
    }
  };
}
