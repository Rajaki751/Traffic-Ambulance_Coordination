import { createContext, useContext, useEffect, useRef } from 'react';
import { connectAdminWebSocket } from '../services/websocket';

export const WebSocketContext = createContext({ status: 'connecting', subscribe: () => () => {} });

export function useAdminWebSocket(onMessage, { onStatusChange, onSessionExpired } = {}) {
  const onMessageRef = useRef(onMessage);
  const onStatusChangeRef = useRef(onStatusChange);
  const onSessionExpiredRef = useRef(onSessionExpired);
  onMessageRef.current = onMessage;
  onStatusChangeRef.current = onStatusChange;
  onSessionExpiredRef.current = onSessionExpired;

  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) return undefined;
    return connectAdminWebSocket(token, (msg) => onMessageRef.current?.(msg), {
      onStatusChange: (status) => onStatusChangeRef.current?.(status),
      onSessionExpired: () => onSessionExpiredRef.current?.(),
    });
  }, []);
}

export function useWebSocketContext() {
  return useContext(WebSocketContext);
}