import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import PageHeader from '../components/PageHeader';

describe('PageHeader Component', () => {
  it('renders title and subtitle correctly', () => {
    render(
      <PageHeader
        title="Live Fleet Map"
        subtitle="Real-time vehicle tracking across Kathmandu"
      />
    );

    expect(screen.getByText('Live Fleet Map')).toBeInTheDocument();
    expect(screen.getByText('Real-time vehicle tracking across Kathmandu')).toBeInTheDocument();
  });

  it('renders action button and handles clicks', () => {
    const handleAction = vi.fn();
    render(
      <PageHeader
        title="Ambulances"
        action={<button onClick={handleAction}>Export CSV</button>}
      />
    );

    const btn = screen.getByText('Export CSV');
    expect(btn).toBeInTheDocument();
    fireEvent.click(btn);
    expect(handleAction).toHaveBeenCalledTimes(1);
  });
});
