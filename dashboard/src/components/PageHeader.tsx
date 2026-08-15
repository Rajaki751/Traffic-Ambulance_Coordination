import React from 'react';

export default function PageHeader({ title, subtitle, children, action }: { title: string; subtitle?: string; children?: React.ReactNode; action?: React.ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">{title}</h1>
        {subtitle && (
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">{subtitle}</p>
        )}
      </div>
      <div className="flex items-center gap-3">
        {children && <>{children}</>}
        {action && <>{action}</>}
      </div>
    </div>
  );
}