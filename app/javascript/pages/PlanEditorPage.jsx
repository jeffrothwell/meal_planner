import React from 'react'
import { Link, useParams } from 'react-router-dom'

export default function PlanEditorPage() {
  const { id } = useParams()
  const isEditing = Boolean(id)
  return (
    <div>
      <h1>{isEditing ? `Edit plan #${id}` : 'New plan'}</h1>
      <p>Coming in Phase 4 — <Link to="/meal_plans">back to plans</Link>.</p>
    </div>
  )
}
