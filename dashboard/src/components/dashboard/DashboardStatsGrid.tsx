import { IconAlarm, IconAmbulance, IconCircleCheck, IconShieldCheck } from '@tabler/icons-react';
import StatCard from '../StatCard';
import { AnalyticsSummary } from '../../types';

interface DashboardStatsGridProps {
  summary: AnalyticsSummary | null;
}

export default function DashboardStatsGrid({ summary }: DashboardStatsGridProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard
        title="Active Emergencies"
        value={summary?.active_emergencies ?? 0}
        icon={IconAlarm}
        color="red"
      />
      <StatCard
        title="Ambulances"
        value={summary?.total_ambulances ?? 0}
        icon={IconAmbulance}
        color="blue"
      />
      <StatCard
        title="Traffic Officers"
        value={summary?.total_officers ?? 0}
        icon={IconShieldCheck}
        color="orange"
      />
      <StatCard
        title="Completed Today"
        value={summary?.completed_emergencies_today ?? 0}
        icon={IconCircleCheck}
        color="green"
      />
    </div>
  );
}
