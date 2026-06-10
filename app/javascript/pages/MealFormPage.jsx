import React from 'react'
import { Link, useParams } from 'react-router-dom'

export default function MealFormPage() {
  const { id } = useParams()
  const isEditing = Boolean(id)
  return (
    <div>
      <h1>{isEditing ? `Edit meal #${id}` : 'New meal'}</h1>
      <p>Coming in Phase 4 — <Link to="/meals">back to meals</Link>.</p>
    </div>
  )
}
