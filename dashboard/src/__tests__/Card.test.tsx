import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import Card from '../components/Card';
import StatusPill from '../components/StatusPill';

describe('Dashboard Component Tests', () => {
  it('renders Card with title, subtitle, and children', () => {
    render(
      <Card title="Fleet Status" subtitle="Overview of vehicles">
        <div>Card Content Inner</div>
      </Card>
    );

    expect(screen.getByText('Fleet Status')).toBeInTheDocument();
    expect(screen.getByText('Overview of vehicles')).toBeInTheDocument();
    expect(screen.getByText('Card Content Inner')).toBeInTheDocument();
  });

  it('renders StatusPill with correct status formatting', () => {
    const { rerender } = render(<StatusPill label="Available" tone="green" />);
    expect(screen.getByText('Available')).toBeInTheDocument();

    rerender(<StatusPill label="Emergency" tone="red" />);
    expect(screen.getByText('Emergency')).toBeInTheDocument();
  });
});
