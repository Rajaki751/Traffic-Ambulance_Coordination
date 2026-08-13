export default function ErrorBanner({ message, onRetry }) {
  return (
    <div className="mb-4 flex items-center justify-between rounded-lg border border-red-200 bg-red-50 p-4 dark:border-red-800 dark:bg-red-900/20">
      <p className="text-sm text-red-700 dark:text-red-300">{message}</p>
      <button
        onClick={onRetry}
        className="rounded bg-red-600 px-3 py-1 text-xs font-medium text-white hover:bg-red-700"
      >
        Retry
      </button>
    </div>
  );
}
