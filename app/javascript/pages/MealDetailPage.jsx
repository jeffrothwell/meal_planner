import React from 'react'
import { Link, useParams } from 'react-router-dom'

export default function MealDetailPage() {
  const { id } = useParams()
  return (
    <div>
      <h1>Meal #{id}</h1>
      <p>Coming in Phase 4 — <Link to="/meals">back to meals</Link>.</p>
    </div>
  )
}
