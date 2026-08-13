import { useCallback, useRef, useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { IconActivity, IconLogout } from '@tabler/icons-react';
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
        <header className="sticky top-0 z-10 flex items-center justify-between border-b bg-white/90 px-6 py-4 backdrop-blur dark:border-gray-700 dark:bg-gray-900/90">
          <h2 className="text-lg font-semibold tracking-tight">System Monitor</h2>
          <div className="flex items-center gap-3">
            <span className="flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm dark:border-gray-700">
              <span
                className={`h-2 w-2 animate-pulse rounded-full ${statusStyles[status] || 'bg-gray-400'}`}
              />
              <span className="flex items-center gap-1.5">
                <IconActivity className="h-4 w-4 text-gray-400" stroke={1.7} />
                {statusLabels[status] || status}
              </span>
            </span>
            <button
              onClick={logout}
              className="flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-medium transition-colors hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-800"
            >
              <IconLogout className="h-4 w-4" stroke={1.7} />
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
