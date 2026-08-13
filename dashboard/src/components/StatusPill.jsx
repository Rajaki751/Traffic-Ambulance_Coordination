const tones = {
  red: 'bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-300',
  green: 'bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300',
  blue: 'bg-blue-50 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300',
  orange: 'bg-orange-50 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300',
  gray: 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300',
};

const dots = {
  red: 'bg-red-500',
  green: 'bg-green-500',
  blue: 'bg-blue-500',
  orange: 'bg-orange-500',
  gray: 'bg-gray-400',
};

export default function StatusPill({ tone = 'gray', label, pulse = false, dot = true }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${tones[tone]}`}
    >
      {dot && (
        <span
          className={`h-1.5 w-1.5 rounded-full ${dots[tone]} ${pulse ? 'animate-pulse' : ''}`}
        />
      )}
      {label}
    </span>
  );
}