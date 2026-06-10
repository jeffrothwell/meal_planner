// Parse a "YYYY-MM-DD" string as a local date and return a long-form human-readable
// string, e.g. "May 30, 2026". Used in plan headings throughout the app.
export function formatWeekDate(dateStr) {
  const [year, month, day] = dateStr.split('-').map(Number)
  return new Date(year, month - 1, day)
    .toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
}
