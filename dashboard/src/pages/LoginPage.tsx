import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  IconAlarm,
  IconAmbulance,
  IconBroadcast,
  IconEye,
  IconEyeOff,
  IconLock,
  IconLockAccess,
  IconMail,
  IconMapPin,
  IconRoute,
  IconShieldCheck,
} from '@tabler/icons-react';
import { authApi } from '../services/api';

const features = [
  {
    icon: IconBroadcast,
    title: 'Live Fleet Tracking',
    text: 'Every ambulance on the map, updated in real time',
  },
  {
    icon: IconRoute,
    title: 'Smart Routing',
    text: 'AI-optimized routes with traffic-aware ETAs',
  },
  {
    icon: IconAlarm,
    title: 'Instant Dispatch',
    text: 'One-click emergency activation and coordination',
  },
];

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
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
    <div className="flex min-h-screen">
      <div className="relative hidden w-1/2 flex-col justify-between overflow-hidden bg-gradient-to-br from-emergency-dark to-emergency p-10 text-white lg:flex">
        <div
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: 'radial-gradient(circle, rgba(255,255,255,0.6) 1px, transparent 1px)',
            backgroundSize: '26px 26px',
          }}
        />
        <div className="absolute -bottom-24 -right-24 h-72 w-72 rounded-full bg-white/10 blur-2xl" />
        <div className="absolute -top-16 -left-16 h-56 w-56 rounded-full bg-black/10 blur-2xl" />

        <div className="relative flex items-center gap-3">
          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-white shadow-sm">
            <IconAmbulance className="h-6 w-6 text-emergency-dark" stroke={1.8} />
          </div>
          <div>
            <h1 className="text-base font-bold leading-tight tracking-tight">
              Emergency Route Coordinator
            </h1>
            <p className="text-xs text-white/60">Government Emergency Network</p>
          </div>
        </div>

        <div className="relative max-w-md">
          <span className="inline-flex items-center gap-2 rounded-full border border-white/25 bg-white/10 px-3 py-1.5 text-xs font-medium backdrop-blur">
            <IconShieldCheck className="h-4 w-4" stroke={1.7} />
            Authorized access only
          </span>
          <h2 className="mt-5 text-4xl font-bold leading-tight tracking-tight">
            Coordinates the fleet. Clears the way. Saves time.
          </h2>
          <p className="mt-3 text-sm text-white/70">
            Admin console for ambulance dispatch, live GPS tracking and emergency
            session coordination.
          </p>
          <div className="mt-8 space-y-4">
            {features.map((f) => (
              <div key={f.title} className="flex items-start gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white/10 backdrop-blur">
                  <f.icon className="h-5 w-5" stroke={1.7} />
                </span>
                <div>
                  <p className="text-sm font-semibold">{f.title}</p>
                  <p className="text-xs text-white/60">{f.text}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="relative flex items-center gap-2 text-xs text-white/60">
          <IconBroadcast className="h-4 w-4" stroke={1.7} />
          Live operational network · 24/7 dispatch support
        </div>
      </div>

      <div className="flex w-full items-center justify-center bg-gray-50 p-6 dark:bg-gray-900 lg:w-1/2">
        <form
          onSubmit={handleSubmit}
          className="w-full max-w-sm"
        >
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-emergency/10 ring-1 ring-emergency/20">
              <IconAmbulance className="h-6 w-6 text-emergency" stroke={1.8} />
            </div>
            <div>
              <h1 className="text-base font-bold tracking-tight">Emergency Coord</h1>
              <p className="text-xs text-gray-500 dark:text-gray-400">Admin Dashboard</p>
            </div>
          </div>

          <span className="hidden items-center gap-2 text-sm font-medium text-emergency lg:flex">
            <IconLockAccess className="h-4 w-4" stroke={1.7} />
            Admin Sign In
          </span>
          <h2 className="mt-2 text-3xl font-bold tracking-tight">Welcome back</h2>
          <p className="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
            Sign in to the emergency coordination console
          </p>

          {error && (
            <div className="mt-6 rounded-lg bg-red-50 p-3 text-sm text-red-600 dark:bg-red-900/30 dark:text-red-300">
              {error}
            </div>
          )}

          <label className="mt-6 block">
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
                className="w-full rounded-lg border border-gray-300 bg-white py-2.5 pl-9 pr-4 transition-shadow focus:border-emergency focus:outline-none focus:ring-2 focus:ring-emergency/20 dark:border-gray-600 dark:bg-gray-800"
                required
              />
            </div>
          </label>
          <label className="mt-4 block">
            <span className="text-sm font-medium">Password</span>
            <div className="relative mt-1">
              <IconLock
                className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400"
                stroke={1.7}
              />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-lg border border-gray-300 bg-white py-2.5 pl-9 pr-11 transition-shadow focus:border-emergency focus:outline-none focus:ring-2 focus:ring-emergency/20 dark:border-gray-600 dark:bg-gray-800"
                required
              />
              <button
                type="button"
                onClick={() => setShowPassword((s) => !s)}
                title={showPassword ? 'Hide password' : 'Show password'}
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 rounded-md p-1 text-gray-400 transition-colors hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-gray-700 dark:hover:text-gray-200"
              >
                {showPassword ? (
                  <IconEyeOff className="h-5 w-5" stroke={1.7} />
                ) : (
                  <IconEye className="h-5 w-5" stroke={1.7} />
                )}
              </button>
            </div>
          </label>
          <button
            type="submit"
            disabled={loading}
            className="mt-6 w-full rounded-lg bg-emergency py-3 font-semibold text-white shadow-sm transition-colors hover:bg-emergency-dark disabled:opacity-50"
          >
            {loading ? 'Signing in...' : 'Sign In'}
          </button>

          <p className="mt-6 flex items-center justify-center gap-1.5 text-center text-xs text-gray-400 dark:text-gray-500">
            <IconLock className="h-3.5 w-3.5" stroke={1.7} />
            Credentials are encrypted · sessions expire automatically
          </p>
        </form>
      </div>
    </div>
  );
}