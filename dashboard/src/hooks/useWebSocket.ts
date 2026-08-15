import { createContext, useContext, useEffect, useRef } from 'react';
import { connectAdminWebSocket } from '../services/websocket';

export const WebSocketContext = createContext<{
  status: string;
  subscribe: (listener: (msg: any) => void) => () => void;
}>({
  status: 'connecting',
  subscribe: () => () => {},
});

interface WSOptions {
  onStatusChange?: (status: string) => void;
  onSessionExpired?: () => void;
}

export function useAdminWebSocket(onMessage: (msg: any) => void, { onStatusChange, onSessionExpired }: WSOptions = {}) {
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