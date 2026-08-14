import axios from 'axios';

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE,
  headers: { 'Content-Type': 'application/json' },
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    if ((status === 401 || status === 403) && localStorage.getItem('token')) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

export const authApi = {
  login: (email, password) =>
    api.post('/api/v1/auth/login', { email, password }),
  me: () => api.get('/api/v1/auth/me'),
};

export const analyticsApi = {
  summary: () => api.get('/api/v1/analytics/summary'),
  ambulances: () => api.get('/api/v1/analytics/ambulances'),
};

export const emergencyApi = {
  active: () => api.get('/api/v1/emergencies/active'),
};

export const gpsApi = {
  liveAll: () => api.get('/api/v1/gps/live/all'),
};

export const usersApi = {
  list: () => api.get('/api/v1/users/'),
  get: (id) => api.get(`/api/v1/users/${id}`),
  create: (data) => api.post('/api/v1/users/', data),
  update: (id, data) => api.put(`/api/v1/users/${id}`, data),
  delete: (id) => api.delete(`/api/v1/users/${id}`),
};

export const ambulancesApi = {
  list: () => api.get('/api/v1/ambulances/'),
};

export default api;
