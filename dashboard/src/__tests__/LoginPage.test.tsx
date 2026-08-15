import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import LoginPage from '../pages/LoginPage';
import { authApi } from '../services/api';

describe('LoginPage Component', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    localStorage.clear();
  });

  it('renders login form with email and password inputs', () => {
    render(
      <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <LoginPage />
      </BrowserRouter>
    );

    expect(screen.getByText('Sign in to the emergency coordination console')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Sign In' })).toBeInTheDocument();
  });

  it('handles FastAPI 422 validation array error gracefully without React child crash', async () => {
    vi.spyOn(authApi, 'login').mockRejectedValueOnce({
      response: {
        status: 422,
        data: {
          detail: [
            {
              type: 'value_error',
              loc: ['body', 'email'],
              msg: 'value is not a valid email address',
              input: 'bad_email',
              ctx: {},
            },
          ],
        },
      },
    });

    const { container } = render(
      <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <LoginPage />
      </BrowserRouter>
    );

    const emailInput = screen.getByPlaceholderText('admin@emergency.gov.np');
    const passwordInput = screen.getByPlaceholderText('Enter password');

    fireEvent.change(emailInput, { target: { value: 'bad_email' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });

    const form = container.querySelector('form')!;
    fireEvent.submit(form);

    await waitFor(() => {
      expect(screen.getByText('value is not a valid email address')).toBeInTheDocument();
    });
  });

  it('displays error if non-admin user attempts login', async () => {
    vi.spyOn(authApi, 'login').mockResolvedValueOnce({
      data: {
        role: 'driver',
        access_token: 'driver_jwt',
      },
    } as any);

    const { container } = render(
      <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <LoginPage />
      </BrowserRouter>
    );

    const emailInput = screen.getByPlaceholderText('admin@emergency.gov.np');
    const passwordInput = screen.getByPlaceholderText('Enter password');

    fireEvent.change(emailInput, { target: { value: 'driver@emergency.gov.np' } });
    fireEvent.change(passwordInput, { target: { value: 'Driver@12345' } });

    const form = container.querySelector('form')!;
    fireEvent.submit(form);

    await waitFor(() => {
      expect(screen.getByText('Admin access only')).toBeInTheDocument();
    });
  });
});
