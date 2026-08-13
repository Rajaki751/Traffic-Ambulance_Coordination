export default function Card({
  title,
  subtitle,
  icon: Icon,
  action,
  children,
  className = '',
  bodyClassName = '',
}) {
  return (
    <section
      className={`overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800 ${className}`}
    >
      {(title || action) && (
        <header className="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-gray-700/60">
          <div className="flex min-w-0 items-center gap-2.5">
            {Icon && (
              <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-gray-50 text-gray-500 dark:bg-gray-700/60 dark:text-gray-400">
                <Icon className="h-5 w-5" stroke={1.7} />
              </span>
            )}
            <div className="min-w-0">
              <h2 className="truncate text-sm font-semibold tracking-tight">{title}</h2>
              {subtitle && (
                <p className="truncate text-xs text-gray-500 dark:text-gray-400">
                  {subtitle}
                </p>
              )}
            </div>
          </div>
          {action}
        </header>
      )}
      <div className={bodyClassName}>{children}</div>
    </section>
  );
}