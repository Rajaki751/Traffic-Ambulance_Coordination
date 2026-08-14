import PageHeader from '../components/PageHeader';
import ErrorBanner from '../components/ErrorBanner';
import DashboardStatsGrid from '../components/dashboard/DashboardStatsGrid';
import DashboardMapCard from '../components/dashboard/DashboardMapCard';
import ActiveSessionsCard from '../components/dashboard/ActiveSessionsCard';
import ResponseTrendCard from '../components/dashboard/ResponseTrendCard';
import FleetActivityCard from '../components/dashboard/FleetActivityCard';
import { useDashboardData } from '../hooks/useDashboardData';

export default function DashboardPage() {
  const {
    summary,
    ambulances,
    liveLocations,
    emergencies,
    trend,
    error,
    mapCenter,
    loadData,
  } = useDashboardData();

  return (
    <div className="space-y-6">
      <PageHeader
        title="Real-Time Dashboard"
        subtitle="Live status of the fleet, active emergencies and response performance"
      />
      {error && <ErrorBanner message={error} onRetry={loadData} />}

      <DashboardStatsGrid summary={summary} />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <DashboardMapCard liveLocations={liveLocations} mapCenter={mapCenter} />

        <div className="space-y-6">
          <ActiveSessionsCard emergencies={emergencies} />
          <ResponseTrendCard 
            trendData={trend} 
            avgResponseTime={summary?.avg_response_time_minutes} 
          />
          <FleetActivityCard ambulances={ambulances} />
        </div>
      </div>
    </div>
  );
}