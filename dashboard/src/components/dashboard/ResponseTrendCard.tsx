import { IconClock } from '@tabler/icons-react';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import Card from '../Card';

interface ResponseTrendCardProps {
  trendData: any[];
  avgResponseTime?: number;
}

export default function ResponseTrendCard({ trendData, avgResponseTime = 0 }: ResponseTrendCardProps) {
  return (
    <Card
      title="Response Time Trend"
      subtitle="Historical 7-day average"
      icon={IconClock}
      bodyClassName="p-5"
    >
      <div className="mb-4 flex items-baseline gap-2">
        <p className="text-4xl font-bold tabular-nums tracking-tight text-emergency">
          {avgResponseTime}
        </p>
        <span className="text-base font-medium text-gray-500 dark:text-gray-400">
          min (Current)
        </span>
      </div>
      
      <div className="h-[140px] w-full">
        <ResponsiveContainer width="100%" height="100%">
          <AreaChart
            data={trendData}
            margin={{ top: 5, right: 0, left: -25, bottom: 0 }}
          >
            <defs>
              <linearGradient id="colorTime" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#E53935" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#E53935" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" vertical={false} strokeOpacity={0.2} />
            <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#888' }} />
            <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#888' }} />
            <Tooltip 
              contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}
            />
            <Area
              type="monotone"
              dataKey="time"
              stroke="#E53935"
              strokeWidth={3}
              fillOpacity={1}
              fill="url(#colorTime)"
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}
