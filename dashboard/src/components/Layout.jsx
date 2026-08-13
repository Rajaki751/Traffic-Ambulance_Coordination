import { useCallback, useRef, useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { IconChevronsLeft, IconChevronsRight, IconLogout } from '@tabler/icons-react';
import Sidebar from './Sidebar';
import { useAdminWebSocket, WebSocketContext } from '../hooks/useWebSocket';

export default function Layout() {
  const navigate = useNavigate();
  const [collapsed, setCollapsed] = useState(false);
  const [showLogoutConfirm, setShowLogoutConfirm] = useState(false);
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
    { onSessionExpired: logout }
  );

  return (
    <div className="flex min-h-screen">
      <Sidebar collapsed={collapsed} />
      <div className="flex flex-1 flex-col">
        <header className="sticky top-0 z-10 flex items-center justify-between border-b bg-white/90 px-6 py-4 backdrop-blur dark:border-gray-700 dark:bg-gray-900/90">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setCollapsed((c) => !c)}
              title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
              className="rounded-lg border p-2 transition-colors hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-800"
            >
              {collapsed ? (
                <IconChevronsRight className="h-4 w-4" stroke={1.7} />
              ) : (
                <IconChevronsLeft className="h-4 w-4" stroke={1.7} />
              )}
            </button>
            <h2 className="text-lg font-semibold tracking-tight">System Monitor</h2>
          </div>
          <button
            onClick={() => setShowLogoutConfirm(true)}
            className="flex items-center gap-2 rounded-lg border px-4 py-2 text-sm font-medium transition-colors hover:bg-gray-100 dark:border-gray-700 dark:hover:bg-gray-800"
          >
            <IconLogout className="h-4 w-4" stroke={1.7} />
            Logout
          </button>
        </header>
        <main className="flex-1 overflow-auto p-6">
          <WebSocketContext.Provider value={{ subscribe }}>
            <Outlet />
          </WebSocketContext.Provider>
        </main>
      </div>

      {showLogoutConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="w-full max-w-sm rounded-xl border bg-white p-6 shadow-2xl dark:border-gray-700 dark:bg-gray-800">
            <div className="flex items-center gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-red-50 text-emergency dark:bg-red-900/30">
                <IconLogout className="h-6 w-6" stroke={1.7} />
              </div>
              <h2 className="text-lg font-bold tracking-tight">Log out?</h2>
            </div>
            <p className="mt-3 text-sm text-gray-500 dark:text-gray-400">
              You will need to sign in again to access the dashboard.
            </p>
            <div className="mt-6 flex justify-end gap-3">
              <button
                onClick={() => setShowLogoutConfirm(false)}
                className="rounded-lg border px-4 py-2 text-sm font-medium transition-colors hover:bg-gray-100 dark:border-gray-600 dark:hover:bg-gray-700"
              >
                Cancel
              </button>
              <button
                onClick={logout}
                className="rounded-lg bg-emergency px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-emergency-dark"
              >
                Logout
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}