import axios from 'axios';
import useAuthStore from '../store/authStore';

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1',
  // A free Render instance sleeps after ~15 minutes idle and takes roughly a
  // minute to wake. Without a generous timeout the first request of the day
  // gives up while the server is still booting.
  timeout: 120000,
  headers: {
    'Content-Type': 'application/json'
  }
});

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// A request that dies before the server answers has no `response`. On a
// sleeping instance that is the normal first attempt, so retry it once —
// by then the instance is awake and the second attempt succeeds.
//
// Only safe to repeat requests are retried: reads, and signing in. A POST
// that charges a wallet or creates a record must never be sent twice.
const isSafeToRetry = (config) =>
  config?.method === 'get' || config?.url === '/auth/login';

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
      window.location.href = '/login';
      return Promise.reject(error);
    }

    const { config } = error;
    if (!error.response && config && !config._retried && isSafeToRetry(config)) {
      config._retried = true;
      await new Promise((resolve) => setTimeout(resolve, 2000));
      return api(config);
    }

    return Promise.reject(error);
  }
);
