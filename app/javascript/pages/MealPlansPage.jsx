import React from 'react'
import { Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMealPlans } from '../api/mealPlans'

function formatWeekDate(dateStr) {
  const [year, month, day] = dateStr.split('-').map(Number)
  return new Date(year, month - 1, day)
    .toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' })
}

export default function MealPlansPage() {
  const { data: plans, isPending, isError } = useQuery({
    queryKey: ['mealPlans'],
    queryFn:  getMealPlans,
  })

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
        <h1 style={{ margin: 0 }}>Meal Plans</h1>
        <Link to="/meal_plans/new" className="btn btn--primary">Plan next week →</Link>
      </div>

      {isPending && <p>Loading plans…</p>}
      {isError   && <p>Failed to load plans. Please refresh and try again.</p>}

      {plans?.length === 0 && (
        <p>No plans yet. <Link to="/meal_plans/new">Create your first plan</Link>.</p>
      )}

      {plans?.map(plan => (
        <div key={plan.id} style={{ marginBottom: '2rem', paddingBottom: '1.5rem', borderBottom: '1px solid #e5e5e2' }}>
          <h2 style={{ marginTop: 0 }}>Week of {formatWeekDate(plan.weekStartDate)}</h2>
          <ul style={{ margin: '0.5rem 0' }}>
            {plan.meals.map(meal => (
              <li key={meal.id}>{meal.title}</li>
            ))}
          </ul>
          <p style={{ fontSize: '0.9rem', color: '#555', margin: '0.5rem 0' }}>
            Dinner nights: {plan.meals.reduce((sum, m) => sum + m.dinnerCount, 0)}
          </p>
          <Link to={`/meal_plans/${plan.id}/edit`} className="btn btn--sm">Edit this plan</Link>
        </div>
      ))}
    </div>
  )
}
