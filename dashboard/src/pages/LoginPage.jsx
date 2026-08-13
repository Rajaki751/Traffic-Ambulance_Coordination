import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
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
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-emergency-dark to-emergency">
      <form
        onSubmit={handleSubmit}
        className="w-full max-w-md rounded-2xl bg-white p-8 shadow-2xl dark:bg-gray-800"
      >
        <div className="mb-8 text-center">
          <span className="text-5xl">🚑</span>
          <h1 className="mt-4 text-2xl font-bold">Admin Login</h1>
          <p className="text-sm text-gray-500">Ambulance Coordination System</p>
        </div>
        {error && (
          <div className="mb-4 rounded-lg bg-red-50 p-3 text-sm text-red-600">{error}</div>
        )}
        <label className="mb-4 block">
          <span className="text-sm font-medium">Email</span>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="mt-1 w-full rounded-lg border px-4 py-2 dark:bg-gray-700"
            required
          />
        </label>
        <label className="mb-6 block">
          <span className="text-sm font-medium">Password</span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 w-full rounded-lg border px-4 py-2 dark:bg-gray-700"
            required
          />
        </label>
        <button
          type="submit"
          disabled={loading}
          className="w-full rounded-lg bg-emergency py-3 font-semibold text-white hover:bg-emergency-dark disabled:opacity-50"
        >
          {loading ? 'Signing in...' : 'Sign In'}
        </button>
      </form>
    </div>
  );
}
