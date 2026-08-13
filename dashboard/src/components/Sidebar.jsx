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

export default function Sidebar({ collapsed = false }) {
  return (
    <aside
      className={`flex flex-col bg-emergency-dark text-white transition-[width] duration-200 ${collapsed ? 'w-20' : 'w-64'}`}
    >
      <div className="flex items-center gap-3 border-b border-white/10 p-6">
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white shadow-sm">
          <IconAmbulance className="h-6 w-6 text-emergency-dark" stroke={1.8} />
        </div>
        {!collapsed && (
          <div className="min-w-0">
            <h1 className="truncate text-base font-bold leading-tight tracking-tight">
              Emergency Coord
            </h1>
            <p className="text-xs text-white/60">Admin Dashboard</p>
          </div>
        )}
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            title={collapsed ? link.label : undefined}
            className={({ isActive }) =>
              `group flex items-center gap-3 rounded-lg px-4 py-3 text-sm transition-colors ${
                collapsed ? 'justify-center px-0' : ''
              } ${
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
            {!collapsed && link.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
