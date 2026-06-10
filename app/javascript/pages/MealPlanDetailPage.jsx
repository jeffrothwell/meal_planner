import React from 'react'
import { Link, useParams } from 'react-router-dom'

export default function MealPlanDetailPage() {
  const { id } = useParams()
  return (
    <div>
      <h1>Meal Plan #{id}</h1>
      <p>Coming in Phase 4 — <Link to="/meal_plans">back to plans</Link>.</p>
    </div>
  )
}
