import { useMemo } from 'react';
import { NavLink } from 'react-router-dom';
import {
  IconAmbulance,
  IconAlarm,
  IconChevronsLeft,
  IconChevronsRight,
  IconLayoutDashboard,
  IconUsers,
} from '@tabler/icons-react';

const navGroups = [
  {
    label: 'Overview',
    links: [{ to: '/', label: 'Dashboard', icon: IconLayoutDashboard }],
  },
  {
    label: 'Operations',
    links: [
      { to: '/emergencies', label: 'Emergencies', icon: IconAlarm },
      { to: '/ambulances', label: 'Ambulances', icon: IconAmbulance },
    ],
  },
  {
    label: 'Administration',
    links: [{ to: '/users', label: 'Users', icon: IconUsers }],
  },
];

function initials(name) {
  return (name || 'A')
    .split(/\s+/)
    .filter(Boolean)
    .map((w) => w[0])
    .slice(0, 2)
    .join('')
    .toUpperCase();
}

export default function Sidebar({ collapsed = false, onToggle }) {
  const user = useMemo(() => {
    try {
      const raw = localStorage.getItem('user');
      return raw ? JSON.parse(raw) : null;
    } catch {
      return null;
    }
  }, []);

  return (
    <aside
      className={`sticky top-0 flex h-screen flex-col bg-emergency-dark text-white transition-[width] duration-200 ${
        collapsed ? 'w-20' : 'w-64'
      }`}
    >
      <div
        className={`flex items-center gap-3 border-b border-white/10 p-6 ${
          collapsed ? 'justify-center px-0' : ''
        }`}
      >
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

      <nav className="flex-1 space-y-5 overflow-y-auto p-4">
        {navGroups.map((group) => (
          <div key={group.label}>
            {!collapsed && (
              <p className="mb-1.5 px-3 text-[10px] font-semibold uppercase tracking-wider text-white/40">
                {group.label}
              </p>
            )}
            <div className="space-y-1">
              {group.links.map((link) => (
                <NavLink
                  key={link.to}
                  to={link.to}
                  end={link.to === '/'}
                  title={collapsed ? link.label : undefined}
                  className={({ isActive }) =>
                    `group relative flex items-center gap-3 rounded-lg py-2.5 text-sm transition-colors ${
                      collapsed ? 'justify-center px-0' : 'px-3'
                    } ${
                      isActive
                        ? 'bg-white/10 font-semibold text-white'
                        : 'text-white/80 hover:bg-white/10 hover:text-white'
                    }`
                  }
                >
                  {({ isActive }) => (
                    <>
                      {isActive && (
                        <span className="absolute left-0 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-white" />
                      )}
                      <link.icon
                        className={`h-5 w-5 shrink-0 ${
                          link.to === '/' ? '' : 'text-white/70 group-hover:text-white'
                        }`}
                        stroke={1.7}
                      />
                      {!collapsed && link.label}
                    </>
                  )}
                </NavLink>
              ))}
            </div>
          </div>
        ))}
      </nav>

      <div className="border-t border-white/10 p-4">
        {!collapsed && user && (
          <div className="mb-3 flex items-center gap-3 rounded-xl bg-white/5 p-3">
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white/15 text-xs font-bold">
              {initials(user.name)}
            </span>
            <div className="min-w-0">
              <p className="truncate text-sm font-medium leading-tight">
                {user.name ?? 'Admin'}
              </p>
              <p className="truncate text-[11px] capitalize text-white/50">
                {user.role ?? 'admin'}
              </p>
            </div>
          </div>
        )}
        <button
          onClick={onToggle}
          title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          className={`flex w-full items-center gap-3 rounded-lg py-2.5 text-sm text-white/60 transition-colors hover:bg-white/10 hover:text-white ${
            collapsed ? 'justify-center px-0' : 'px-3'
          }`}
        >
          {collapsed ? (
            <IconChevronsRight className="h-5 w-5" stroke={1.7} />
          ) : (
            <>
              <IconChevronsLeft className="h-5 w-5" stroke={1.7} />
              Collapse
            </>
          )}
        </button>
      </div>
    </aside>
  );
}