import React from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMeals } from '../api/meals'

const SEASONAL_LABELS = {
  year_round:  'Year round',
  warm_months: 'Warm months (Apr–Sep)',
  cold_months: 'Cold months (Oct–Mar)',
}

function formatDate(dateStr) {
  if (!dateStr) return 'Never'
  // Parse as local date to avoid UTC-offset display issues
  const [year, month, day] = dateStr.split('-').map(Number)
  return new Date(year, month - 1, day)
    .toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

function truncate(str, max) {
  if (!str || str.length <= max) return str
  return str.slice(0, max - 1) + '…'
}

export default function MealsPage() {
  const navigate = useNavigate()
  const { data: meals, isPending, isError } = useQuery({
    queryKey: ['meals'],
    queryFn: getMeals,
  })

  return (
    <div>
      <h1>Meals</h1>

      <div style={{ marginBottom: '1rem' }}>
        <Link to="/meals/new" className="btn">Add meal</Link>
      </div>

      {isPending && <p>Loading meals…</p>}
      {isError   && <p>Failed to load meals. Please refresh and try again.</p>}

      {meals && (
        <table>
          <thead>
            <tr>
              <th>Title</th>
              <th>Description</th>
              <th>Ratings</th>
              <th>Dinner nights</th>
              <th>Season</th>
              <th>Group</th>
              <th>Last planned</th>
            </tr>
          </thead>
          <tbody>
            {meals.map(meal => (
              <tr
                key={meal.id}
                className="clickable-row"
                onClick={() => navigate(`/meals/${meal.id}`)}
              >
                <td>{meal.title}</td>
                <td>{truncate(meal.description, 80)}</td>
                <td>
                  {meal.nutritionRating != null
                    ? <span className="rating-badge">N:{meal.nutritionRating}</span>
                    : <span style={{ color: '#aaa' }}>–</span>}
                  {meal.kidsRating != null
                    ? <span className="rating-badge">K:{meal.kidsRating}</span>
                    : <span style={{ color: '#aaa' }}>–</span>}
                  {meal.adultRating != null
                    ? <span className="rating-badge">A:{meal.adultRating}</span>
                    : <span style={{ color: '#aaa' }}>–</span>}
                </td>
                <td>{meal.dinnerCount}</td>
                <td>{SEASONAL_LABELS[meal.seasonalPreference] ?? '—'}</td>
                <td>{meal.varietyGroup || '—'}</td>
                <td>{formatDate(meal.lastPlanned)}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
