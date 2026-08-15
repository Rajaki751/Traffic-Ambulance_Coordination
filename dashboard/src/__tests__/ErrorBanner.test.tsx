import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import ErrorBanner from '../components/ErrorBanner';

describe('ErrorBanner Component', () => {
  it('renders error message', () => {
    render(<ErrorBanner message="Failed to load dashboard statistics" />);
    expect(screen.getByText('Failed to load dashboard statistics')).toBeInTheDocument();
  });

  it('renders retry button and triggers callback when provided', () => {
    const handleRetry = vi.fn();
    render(<ErrorBanner message="Network timeout" onRetry={handleRetry} />);

    const retryBtn = screen.getByText('Retry');
    expect(retryBtn).toBeInTheDocument();
    fireEvent.click(retryBtn);
    expect(handleRetry).toHaveBeenCalledTimes(1);
  });
});
