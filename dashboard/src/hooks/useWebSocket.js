import { useEffect } from 'react';
import { connectAdminWebSocket } from '../services/websocket';

export function useAdminWebSocket(onMessage) {
  useEffect(() => {
    const token = localStorage.getItem('token');
    if (!token) return;
    const disconnect = connectAdminWebSocket(token, onMessage);
    return disconnect;
  }, [onMessage]);
}
