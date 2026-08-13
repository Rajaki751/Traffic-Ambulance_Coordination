import { Outlet, useNavigate } from 'react-router-dom';
import Sidebar from './Sidebar';

export default function Layout() {
  const navigate = useNavigate();

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <header className="flex items-center justify-between border-b bg-white px-6 py-4 dark:border-gray-700 dark:bg-gray-800">
          <h2 className="text-lg font-semibold">System Monitor</h2>
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-2 text-sm">
              <span className="h-2 w-2 animate-pulse rounded-full bg-green-500" />
              Live
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
          <Outlet />
        </main>
      </div>
    </div>
  );
}
