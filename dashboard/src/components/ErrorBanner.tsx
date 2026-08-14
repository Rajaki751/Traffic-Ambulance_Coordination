import { IconAlertTriangle, IconRefresh } from '@tabler/icons-react';

export default function ErrorBanner({ message, onRetry }) {
  return (
    <div className="mb-4 flex items-center justify-between gap-3 rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20">
      <div className="flex items-center gap-2">
        <IconAlertTriangle className="h-5 w-5 shrink-0 text-red-600 dark:text-red-400" stroke={1.7} />
        <p className="text-sm text-red-700 dark:text-red-300">{message}</p>
      </div>
      <button
        onClick={onRetry}
        className="flex shrink-0 items-center gap-1.5 rounded bg-red-600 px-3 py-1.5 text-xs font-medium text-white transition-colors hover:bg-red-700"
      >
        <IconRefresh className="h-3.5 w-3.5" stroke={2} />
        Retry
      </button>
    </div>
  );
}
