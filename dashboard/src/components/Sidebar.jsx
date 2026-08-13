import { NavLink } from 'react-router-dom';
import {
  IconAmbulance,
  IconAlarm,
  IconLayoutDashboard,
  IconUsers,
} from '@tabler/icons-react';

const links = [
  { to: '/', label: 'Dashboard', icon: IconLayoutDashboard },
  { to: '/emergencies', label: 'Emergencies', icon: IconAlarm },
  { to: '/ambulances', label: 'Ambulances', icon: IconAmbulance },
  { to: '/users', label: 'Users', icon: IconUsers },
];

export default function Sidebar() {
  return (
    <aside className="flex w-64 flex-col bg-emergency-dark text-white">
      <div className="flex items-center gap-3 border-b border-white/10 p-6">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-white shadow-sm">
          <IconAmbulance className="h-6 w-6 text-emergency-dark" stroke={1.8} />
        </div>
        <div>
          <h1 className="text-base font-bold leading-tight tracking-tight">
            Emergency Coord
          </h1>
          <p className="text-xs text-white/60">Admin Dashboard</p>
        </div>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            className={({ isActive }) =>
              `group flex items-center gap-3 rounded-lg px-4 py-3 text-sm transition-colors ${
                isActive
                  ? 'bg-white/20 font-semibold'
                  : 'text-white/80 hover:bg-white/10 hover:text-white'
              }`
            }
          >
            <link.icon
              className={`h-5 w-5 shrink-0 ${
                link.to === '/' ? '' : 'text-white/70 group-hover:text-white'
              }`}
              stroke={1.7}
            />
            {link.label}
          </NavLink>
        ))}
      </nav>
      <div className="border-t border-white/10 p-4">
        <p className="px-2 text-[11px] uppercase tracking-wider text-white/40">
          v1.0.0
        </p>
      </div>
    </aside>
  );
}
