import React from 'react'
import { Link, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMealPlan } from '../api/mealPlans'
import { formatWeekDate } from '../utils/mealPlans'

function nights(count) {
  return `${count} ${count === 1 ? 'night' : 'nights'}`
}

export default function MealPlanDetailPage() {
  const { id } = useParams()

  const { data: plan, isPending, isError } = useQuery({
    queryKey: ['mealPlans', id],
    queryFn:  () => getMealPlan(id),
  })

  if (isPending) return <p>Loading…</p>
  if (isError)   return <p>Plan not found.</p>

  const totalNights = plan.meals.reduce((sum, m) => sum + m.dinnerCount, 0)

  return (
    <div>
      <Link to="/meal_plans" className="btn btn--sm" style={{ marginBottom: '1.25rem', display: 'inline-block' }}>
        ← All plans
      </Link>

      <h1>Week of {formatWeekDate(plan.weekStartDate)}</h1>

      <ul style={{ listStyle: 'none', padding: 0, margin: '0 0 1rem' }}>
        {plan.meals.map(meal => (
          <li key={meal.id} style={{ padding: '0.6rem 0', borderBottom: '1px solid #e5e5e2' }}>
            <span style={{ fontWeight: 600 }}>{meal.title}</span>
            <span style={{ fontSize: '0.85rem', color: '#666', marginLeft: '0.5rem' }}>
              ({nights(meal.dinnerCount)})
            </span>
          </li>
        ))}
      </ul>

      <p style={{ fontSize: '0.95rem', color: '#555' }}>
        Total dinner nights: {totalNights}
      </p>

      <div className="form-actions">
        <Link to={`/meal_plans/${plan.id}/edit`} className="btn btn--primary">
          Edit this plan
        </Link>
      </div>
    </div>
  )
}
