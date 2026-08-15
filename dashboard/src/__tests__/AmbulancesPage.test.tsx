import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import AmbulancesPage from '../pages/AmbulancesPage';
import { ambulancesApi } from '../services/api';

describe('AmbulancesPage', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('fetches and displays ambulance cards with driver information', async () => {
    vi.spyOn(ambulancesApi, 'list').mockResolvedValueOnce({
      data: [
        {
          id: 1,
          vehicle_number: 'BA-2-CHA-1234',
          driver_name: 'Bikram Thapa',
          status: 'emergency',
        },
        {
          id: 2,
          vehicle_number: 'BA-1-JHA-9876',
          driver_name: 'Sunil Shrestha',
          status: 'available',
        },
      ],
    } as any);

    render(<AmbulancesPage />);

    expect(screen.getByText('Ambulance Fleet')).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText('BA-2-CHA-1234')).toBeInTheDocument();
      expect(screen.getByText('Bikram Thapa')).toBeInTheDocument();
      expect(screen.getByText('BA-1-JHA-9876')).toBeInTheDocument();
      expect(screen.getByText('Sunil Shrestha')).toBeInTheDocument();
    });
  });

  it('displays empty state when no ambulances registered', async () => {
    vi.spyOn(ambulancesApi, 'list').mockResolvedValueOnce({ data: [] } as any);

    render(<AmbulancesPage />);

    await waitFor(() => {
      expect(screen.getByText('No ambulances registered')).toBeInTheDocument();
    });
  });
});
