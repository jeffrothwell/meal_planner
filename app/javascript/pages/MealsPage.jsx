import React, { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { getMeals } from '../api/meals'
import { SEASONAL_LABELS, formatDate, truncate } from '../utils/meals'

export default function MealsPage() {
  const navigate       = useNavigate()
  const [query, setQuery] = useState('')

  const { data: meals, isPending, isError } = useQuery({
    queryKey: ['meals'],
    queryFn: getMeals,
  })

  const filteredMeals = meals
    ? meals.filter(m => m.title.toLowerCase().includes(query.toLowerCase()))
    : []

  return (
    <div>
      <h1>Meals</h1>

      <div className="meals-toolbar">
        <input
          type="search"
          className="meals-search"
          placeholder="Search by title…"
          value={query}
          onChange={e => setQuery(e.target.value)}
          aria-label="Search meals by title"
        />
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
            {filteredMeals.length === 0 && (
              <tr><td colSpan={7} style={{ color: '#999', fontStyle: 'italic' }}>No meals match your search.</td></tr>
            )}
            {filteredMeals.map(meal => (
              <tr
                key={meal.id}
                className={`clickable-row${meal.isActive ? '' : ' meal-row--inactive'}`}
                onClick={() => navigate(`/meals/${meal.id}`)}
              >
                <td>
                  {meal.title}
                  {!meal.isActive && <span className="inactive-badge">Inactive</span>}
                </td>
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
