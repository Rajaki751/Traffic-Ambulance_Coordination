export default function StatCard({ title, value, icon, color = 'red' }) {
  const colors = {
    red: 'bg-emergency/10 text-emergency border-emergency/20',
    blue: 'bg-blue-50 text-blue-600 border-blue-200 dark:bg-blue-900/30 dark:text-blue-300',
    green: 'bg-green-50 text-green-600 border-green-200 dark:bg-green-900/30 dark:text-green-300',
    orange: 'bg-orange-50 text-orange-600 border-orange-200 dark:bg-orange-900/30 dark:text-orange-300',
  };

  return (
    <div className={`rounded-xl border p-5 ${colors[color]}`}>
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium opacity-80">{title}</p>
          <p className="mt-1 text-3xl font-bold">{value}</p>
        </div>
        <span className="text-3xl opacity-60">{icon}</span>
      </div>
    </div>
  );
}
