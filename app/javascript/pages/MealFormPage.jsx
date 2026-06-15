import React, { useState, useEffect } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getMeal, getMeals, createMeal, updateMeal } from '../api/meals'
import { SEASONAL_LABELS } from '../utils/meals'

const EMPTY_FORM = {
  title:              '',
  description:        '',
  nutritionRating:    '',
  kidsRating:         '',
  adultRating:        '',
  dinnerCount:        1,
  varietyGroup:       '',
  seasonalPreference: 'year_round',
  recipeUrl:          '',
  isActive:           true,
}

// Show any error messages for a field below its input.
function FieldError({ errors, field }) {
  const messages = errors[field]
  if (!messages?.length) return null
  return <p className="field-error">{messages.join(', ')}</p>
}

export default function MealFormPage() {
  const { id }      = useParams()
  const isEditing   = Boolean(id)
  const navigate    = useNavigate()
  const queryClient = useQueryClient()

  const [form,        setForm]        = useState(EMPTY_FORM)
  const [fieldErrors, setFieldErrors] = useState({})

  const { data: existingMeal, isPending: loadingMeal } = useQuery({
    queryKey: ['meals', id],
    queryFn:  () => getMeal(id),
    enabled:  isEditing,
  })

  // Variety-group datalist — re-uses the cached meals list if already fetched
  const { data: allMeals } = useQuery({
    queryKey:  ['meals'],
    queryFn:   getMeals,
    staleTime: 5 * 60 * 1000,
  })
  const varietyGroupOptions = [
    ...new Set((allMeals || []).map(m => m.varietyGroup).filter(Boolean)),
  ].sort()

  useEffect(() => {
    if (!existingMeal) return
    setForm({
      title:              existingMeal.title              ?? '',
      description:        existingMeal.description        ?? '',
      nutritionRating:    existingMeal.nutritionRating    ?? '',
      kidsRating:         existingMeal.kidsRating         ?? '',
      adultRating:        existingMeal.adultRating        ?? '',
      dinnerCount:        existingMeal.dinnerCount        ?? 1,
      varietyGroup:       existingMeal.varietyGroup       ?? '',
      seasonalPreference: existingMeal.seasonalPreference ?? 'year_round',
      recipeUrl:          existingMeal.recipeUrl          ?? '',
      isActive:           existingMeal.isActive           ?? true,
    })
  }, [existingMeal])

  const mutation = useMutation({
    mutationFn: (data) => isEditing ? updateMeal(id, data) : createMeal(data),
    onSuccess: (meal) => {
      queryClient.invalidateQueries({ queryKey: ['meals'] })
      navigate(`/meals/${meal.id}`, {
        state: { notice: isEditing ? 'Meal updated.' : 'Meal added.' },
      })
    },
    onError: (err) => {
      setFieldErrors(err.data?.errors ?? {})
      window.scrollTo(0, 0)
    },
  })

  function handleChange(e) {
    const { name, value, type, checked } = e.target
    const newValue = type === 'checkbox' ? checked : value
    setForm(prev => ({ ...prev, [name]: newValue }))
    if (fieldErrors[name]) {
      setFieldErrors(prev => { const next = { ...prev }; delete next[name]; return next })
    }
  }

  function handleSubmit(e) {
    e.preventDefault()
    setFieldErrors({})
    mutation.mutate({
      title:               form.title,
      description:         form.description,
      nutrition_rating:    form.nutritionRating  === '' ? null : Number(form.nutritionRating),
      kids_rating:         form.kidsRating        === '' ? null : Number(form.kidsRating),
      adult_rating:        form.adultRating       === '' ? null : Number(form.adultRating),
      dinner_count:        Number(form.dinnerCount),
      variety_group:       form.varietyGroup   || null,
      seasonal_preference: form.seasonalPreference,
      recipe_url:          form.recipeUrl      || null,
      is_active:           form.isActive,
    })
  }

  if (isEditing && loadingMeal) return <p>Loading…</p>

  const hasErrors = Object.keys(fieldErrors).length > 0

  return (
    <div>
      <h1>{isEditing ? `Edit ${existingMeal?.title ?? 'meal'}` : 'Add a meal'}</h1>

      {hasErrors && (
        <div className="flash-alert">
          Please fix the errors below before saving.
        </div>
      )}

      <form onSubmit={handleSubmit} noValidate>
        <div className="form-group">
          <label htmlFor="title">Title</label>
          <input
            id="title" name="title" type="text"
            value={form.title} onChange={handleChange}
            aria-invalid={!!fieldErrors.title}
          />
          <FieldError errors={fieldErrors} field="title" />
        </div>

        <div className="form-group">
          <label htmlFor="description">Description</label>
          <textarea
            id="description" name="description"
            value={form.description} onChange={handleChange}
            aria-invalid={!!fieldErrors.description}
          />
          <FieldError errors={fieldErrors} field="description" />
        </div>

        <div className="form-group">
          <label htmlFor="nutritionRating">Nutrition rating</label>
          <input
            id="nutritionRating" name="nutritionRating" type="number"
            min="0" max="10"
            value={form.nutritionRating} onChange={handleChange}
            aria-invalid={!!fieldErrors.nutritionRating}
          />
          <FieldError errors={fieldErrors} field="nutritionRating" />
          <p className="form-hint">0–10, leave blank if unknown</p>
        </div>

        <div className="form-group">
          <label htmlFor="kidsRating">Kids rating</label>
          <input
            id="kidsRating" name="kidsRating" type="number"
            min="0" max="10"
            value={form.kidsRating} onChange={handleChange}
            aria-invalid={!!fieldErrors.kidsRating}
          />
          <FieldError errors={fieldErrors} field="kidsRating" />
          <p className="form-hint">0–10, leave blank if unknown</p>
        </div>

        <div className="form-group">
          <label htmlFor="adultRating">Adult rating</label>
          <input
            id="adultRating" name="adultRating" type="number"
            min="0" max="10"
            value={form.adultRating} onChange={handleChange}
            aria-invalid={!!fieldErrors.adultRating}
          />
          <FieldError errors={fieldErrors} field="adultRating" />
          <p className="form-hint">0–10, leave blank if unknown</p>
        </div>

        <div className="form-group">
          <label htmlFor="dinnerCount">Dinner nights</label>
          <input
            id="dinnerCount" name="dinnerCount" type="number"
            min="1"
            value={form.dinnerCount} onChange={handleChange}
            aria-invalid={!!fieldErrors.dinnerCount}
          />
          <FieldError errors={fieldErrors} field="dinnerCount" />
          <p className="form-hint">
            How many dinner nights does this meal typically cover? (e.g. Pizza = 2)
          </p>
        </div>

        <div className="form-group">
          <label htmlFor="varietyGroup">Variety group</label>
          <input
            id="varietyGroup" name="varietyGroup" type="text"
            list="variety-group-options"
            placeholder="e.g. soup, mexican, burger"
            value={form.varietyGroup} onChange={handleChange}
            aria-invalid={!!fieldErrors.varietyGroup}
          />
          <datalist id="variety-group-options">
            {varietyGroupOptions.map(g => <option key={g} value={g} />)}
          </datalist>
          <FieldError errors={fieldErrors} field="varietyGroup" />
          <p className="form-hint">
            Meals in the same group won't both appear in the same week's suggestions.
            Leave blank for no restriction.
          </p>
        </div>

        <div className="form-group">
          <label htmlFor="seasonalPreference">Seasonal preference</label>
          <select
            id="seasonalPreference" name="seasonalPreference"
            value={form.seasonalPreference} onChange={handleChange}
            aria-invalid={!!fieldErrors.seasonalPreference}
          >
            {Object.entries(SEASONAL_LABELS).map(([value, label]) => (
              <option key={value} value={value}>{label}</option>
            ))}
          </select>
          <FieldError errors={fieldErrors} field="seasonalPreference" />
          <p className="form-hint">Limits when this meal is suggested during plan generation.</p>
        </div>

        <div className="form-group">
          <label htmlFor="recipeUrl">Recipe URL</label>
          <input
            id="recipeUrl" name="recipeUrl" type="url"
            value={form.recipeUrl} onChange={handleChange}
            aria-invalid={!!fieldErrors.recipeUrl}
          />
          <FieldError errors={fieldErrors} field="recipeUrl" />
        </div>

        <div className="form-group">
          <label className="checkbox-label">
            <input
              type="checkbox"
              name="isActive"
              checked={form.isActive}
              onChange={handleChange}
            />
            Active
          </label>
          <p className="form-hint">
            Inactive meals are hidden from plan suggestions and the meal picker.
          </p>
        </div>

        <div className="form-actions">
          <button
            type="submit"
            className="btn btn--primary"
            disabled={mutation.isPending}
          >
            {mutation.isPending
              ? 'Saving…'
              : isEditing ? 'Update meal' : 'Add meal'}
          </button>
        </div>
      </form>

      <div style={{ marginTop: '0.75rem' }}>
        {isEditing
          ? <Link to={`/meals/${id}`}>← Back</Link>
          : <Link to="/meals">← Cancel</Link>}
      </div>
    </div>
  )
}
