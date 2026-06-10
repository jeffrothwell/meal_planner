export const SEASONAL_LABELS = {
  year_round:  'Year round',
  warm_months: 'Warm months (Apr–Sep)',
  cold_months: 'Cold months (Oct–Mar)',
}

// Parse a "YYYY-MM-DD" string as a local date (avoids UTC-offset display issues)
// and return a human-readable string, e.g. "May 16, 2026". Returns "Never" for null/undefined.
export function formatDate(dateStr) {
  if (!dateStr) return 'Never'
  const [year, month, day] = dateStr.split('-').map(Number)
  return new Date(year, month - 1, day)
    .toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

export function truncate(str, max) {
  if (!str || str.length <= max) return str
  return str.slice(0, max - 1) + '…'
}
