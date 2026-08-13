import { NavLink } from 'react-router-dom';

const links = [
  { to: '/', label: 'Dashboard', icon: '📊' },
  { to: '/emergencies', label: 'Emergencies', icon: '🚨' },
  { to: '/ambulances', label: 'Ambulances', icon: '🚑' },
  { to: '/users', label: 'Users', icon: '👥' },
];

export default function Sidebar() {
  return (
    <aside className="flex w-64 flex-col bg-emergency-dark text-white">
      <div className="border-b border-white/10 p-6">
        <h1 className="text-lg font-bold">Ambulance Coord</h1>
        <p className="text-xs text-white/60">Admin Dashboard</p>
      </div>
      <nav className="flex-1 space-y-1 p-4">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 rounded-lg px-4 py-3 text-sm transition ${
                isActive ? 'bg-white/20 font-semibold' : 'hover:bg-white/10'
              }`
            }
          >
            <span>{link.icon}</span>
            {link.label}
          </NavLink>
        ))}
      </nav>
    </aside>
  );
}
