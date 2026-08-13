import { useCallback, useRef, useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';
import { useAdminWebSocket, WebSocketContext } from '../hooks/useWebSocket';

const statusStyles = {
  open: 'bg-green-500',
  connecting: 'bg-yellow-500',
  reconnecting: 'bg-yellow-500',
  closed: 'bg-red-500',
};

const statusLabels = {
  open: 'Live',
  connecting: 'Connecting',
  reconnecting: 'Reconnecting',
  closed: 'Offline',
};

export default function Layout() {
  const navigate = useNavigate();
  const [status, setStatus] = useState('connecting');
  const listenersRef = useRef(new Set());

  const subscribe = useCallback((listener) => {
    listenersRef.current.add(listener);
    return () => {
      listenersRef.current.delete(listener);
    };
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  }, [navigate]);

  useAdminWebSocket(
    (msg) => listenersRef.current.forEach((listener) => listener(msg)),
    { onStatusChange: setStatus, onSessionExpired: logout }
  );

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b bg-white px-6 py-4 dark:border-gray-700 dark:bg-gray-800">
          <h2 className="text-lg font-semibold">System Monitor</h2>
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2 text-sm">
              <span className={`h-2 w-2 animate-pulse rounded-full ${statusStyles[status] || 'bg-gray-400'}`} />
              {statusLabels[status] || status}
            </span>
            <button
              onClick={logout}
              className="rounded-lg bg-gray-100 px-4 py-2 text-sm hover:bg-gray-200 dark:bg-gray-700"
            >
              Logout
            </button>
          </div>
        </header>
        <main className="flex-1 overflow-auto p-6">
          <WebSocketContext.Provider value={{ status, subscribe }}>
            <Outlet />
          </WebSocketContext.Provider>
        </main>
      </div>
    </div>
  );
}