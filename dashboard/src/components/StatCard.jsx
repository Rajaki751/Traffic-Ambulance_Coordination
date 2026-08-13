export default function StatCard({ title, value, icon: Icon, color = 'red' }) {
  const colors = {
    red: 'bg-emergency/10 text-emergency border-emergency/20',
    blue: 'bg-blue-50 text-blue-600 border-blue-200 dark:bg-blue-900/30 dark:text-blue-300',
    green:
      'bg-green-50 text-green-600 border-green-200 dark:bg-green-900/30 dark:text-green-300',
    orange:
      'bg-orange-50 text-orange-600 border-orange-200 dark:bg-orange-900/30 dark:text-orange-300',
  };

  const tileColors = {
    red: 'bg-emergency/10 text-emergency',
    blue: 'bg-blue-100 text-blue-600 dark:bg-blue-900/40 dark:text-blue-300',
    green: 'bg-green-100 text-green-600 dark:bg-green-900/40 dark:text-green-300',
    orange:
      'bg-orange-100 text-orange-600 dark:bg-orange-900/40 dark:text-orange-300',
  };

  return (
    <div
      className={`rounded-2xl border p-5 shadow-sm transition-shadow hover:shadow-md ${colors[color]}`}
    >
      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0">
          <p className="text-sm font-medium opacity-80">{title}</p>
          <p className="mt-1 text-3xl font-bold tabular-nums tracking-tight">{value}</p>
        </div>
        <div
          className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl ${tileColors[color]}`}
        >
          {Icon && <Icon className="h-6 w-6" stroke={1.7} />}
        </div>
      </div>
    </div>
  );
}