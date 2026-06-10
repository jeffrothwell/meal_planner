import React from 'react'
import { Link, useParams, useLocation } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMeal } from '../api/meals'
import { SEASONAL_LABELS } from '../utils/meals'

export default function MealDetailPage() {
  const { id } = useParams()
  const location = useLocation()
  const notice = location.state?.notice

  const { data: meal, isPending, isError } = useQuery({
    queryKey: ['meals', id],
    queryFn: () => getMeal(id),
  })

  if (isPending) return <p>Loading…</p>
  if (isError)   return <p>Meal not found.</p>

  return (
    <div>
      <h1>{meal.title}</h1>

      {notice && <div className="flash-notice">{notice}</div>}

      <p>{meal.description}</p>

      <h2>Ratings</h2>
      <p>
        {meal.nutritionRating != null
          ? <span className="rating-badge">Nutrition: {meal.nutritionRating}/10</span>
          : <span style={{ color: '#aaa' }}>Nutrition: –</span>}
        {' '}
        {meal.kidsRating != null
          ? <span className="rating-badge">Kids: {meal.kidsRating}/10</span>
          : <span style={{ color: '#aaa' }}>Kids: –</span>}
        {' '}
        {meal.adultRating != null
          ? <span className="rating-badge">Adult: {meal.adultRating}/10</span>
          : <span style={{ color: '#aaa' }}>Adult: –</span>}
      </p>

      <p><strong>Dinner nights per use:</strong> {meal.dinnerCount}</p>
      <p><strong>Season:</strong> {SEASONAL_LABELS[meal.seasonalPreference]}</p>
      <p><strong>Variety group:</strong> {meal.varietyGroup || 'None'}</p>

      {meal.recipeUrl && (
        <p>
          <a href={meal.recipeUrl} target="_blank" rel="noopener noreferrer">
            View recipe →
          </a>
        </p>
      )}

      <div className="form-actions">
        <Link to={`/meals/${meal.id}/edit`} className="btn">Edit</Link>
        <Link to="/meals" className="btn">← Back to meals</Link>
      </div>
    </div>
  )
}
