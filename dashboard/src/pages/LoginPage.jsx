import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { IconAmbulance, IconLock, IconMail } from '@tabler/icons-react';
import { authApi } from '../services/api';

export default function LoginPage() {
  const [email, setEmail] = useState('admin@ambulance.gov');
  const [password, setPassword] = useState('Admin@12345');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const { data } = await authApi.login(email, password);
      if (data.role !== 'admin') {
        setError('Admin access only');
        setLoading(false);
        return;
      }
      localStorage.setItem('token', data.access_token);
      localStorage.setItem('user', JSON.stringify(data));
      navigate('/');
    } catch (err) {
      if (!err.response) {
        setError('Cannot reach API server. Start backend: uvicorn app.main:app --port 8000');
      } else if (err.response.status === 401) {
        setError('Invalid email or password');
      } else {
        setError(err.response.data?.detail || 'Login failed');
      }
    }
    setLoading(false);
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-emergency-dark to-emergency p-4">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md rounded-2xl bg-white p-8 shadow-2xl dark:bg-gray-800"
      >
        <div className="mb-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-emergency/10 ring-1 ring-emergency/20">
            <IconAmbulance className="h-9 w-9 text-emergency" stroke={1.6} />
          </div>
          <h1 className="mt-4 text-2xl font-bold tracking-tight">Admin Login</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Emergency Route Coordination
          </p>
        </div>
        {error && (
          <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-300">
            {error}
          </div>
        )}
        <label className="mb-4 block">
          <span className="text-sm font-medium">Email</span>
          <div className="relative mt-1">
            <IconMail
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400"
              stroke={1.7}
            />
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-4 focus:border-emergency focus:outline-none focus:ring-2 focus:ring-emergency/20 dark:border-gray-600 dark:bg-gray-700"
              required
            />
          </div>
        </label>
        <label className="mb-6 block">
          <span className="text-sm font-medium">Password</span>
          <div className="relative mt-1">
            <IconLock
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400"
              stroke={1.7}
            />
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-lg border border-gray-300 py-2 pl-9 pr-4 focus:border-emergency focus:outline-none focus:ring-2 focus:ring-emergency/20 dark:border-gray-600 dark:bg-gray-700"
              required
            />
          </div>
        </label>
        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-emergency py-3 font-semibold text-white transition-colors hover:bg-emergency-dark disabled:opacity-50"
        >
          {loading ? 'Signing in...' : 'Sign In'}
        </button>
      </form>
    </div>
  );
}
