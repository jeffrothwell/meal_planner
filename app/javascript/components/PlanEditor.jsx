import React, { useReducer, useState } from 'react'
import { useMutation } from '@tanstack/react-query'
import { generateMealPlan, suggestSwap } from '../api/mealPlans'

// ── Reducer ─────────────────────────────────────────────────────────────────

function reducer(state, action) {
  switch (action.type) {
    case 'SET_MEALS':
      return { ...state, meals: action.meals, swapOpenId: null }

    case 'SET_MEAL_COUNT':
      return { ...state, mealCount: action.mealCount }

    case 'REMOVE_MEAL': {
      const { id } = action
      return {
        ...state,
        meals: state.meals.filter(m => m.id !== id),
        manuallyExcludedIds: state.manuallyExcludedIds.includes(id)
          ? state.manuallyExcludedIds
          : [...state.manuallyExcludedIds, id],
        swapOpenId: state.swapOpenId === id ? null : state.swapOpenId,
      }
    }

    case 'OPEN_SWAP':
      // Close any other open panel, or toggle this one closed
      return {
        ...state,
        swapOpenId: state.swapOpenId === action.id ? null : action.id,
      }

    case 'CLOSE_SWAP':
      return { ...state, swapOpenId: null }

    case 'SWAP_MEAL': {
      // Replace the meal at its current index with one or more replacements.
      // Also records the displaced meal as excluded so it won't be suggested again.
      const { id, replacements } = action
      const idx = state.meals.findIndex(m => m.id === id)
      const newMeals = [
        ...state.meals.slice(0, idx),
        ...replacements,
        ...state.meals.slice(idx + 1),
      ]
      return {
        ...state,
        meals: newMeals,
        manuallyExcludedIds: state.manuallyExcludedIds.includes(id)
          ? state.manuallyExcludedIds
          : [...state.manuallyExcludedIds, id],
        swapOpenId: null,
      }
    }

    case 'ADD_MEAL':
      return { ...state, meals: [...state.meals, action.meal] }

    default:
      return state
  }
}

// ── Status bar ───────────────────────────────────────────────────────────────

function StatusBar({ meals, mealCount }) {
  const nights = meals.reduce((sum, m) => sum + m.dinnerCount, 0)
  const diff   = nights - mealCount

  let modifier = 'plan-editor__status--ok'
  let message  = `${nights} of ${mealCount} dinner nights planned — looking good!`

  if (diff < 0) {
    modifier = 'plan-editor__status--short'
    message  = `${nights} of ${mealCount} dinner nights planned — ${-diff} more needed.`
  } else if (diff > 0) {
    modifier = 'plan-editor__status--over'
    message  = `${nights} of ${mealCount} dinner nights planned — ${diff} over target.`
  }

  return <div className={`plan-editor__status ${modifier}`}>{message}</div>
}

// ── Meal item ────────────────────────────────────────────────────────────────

function MealItem({ meal, isSwapOpen, availableMeals, isPicking, onOpenSwap, onRemove, onManualSwap, onPickForMe }) {
  const [selectedId, setSelectedId] = useState('')

  const ratings = [
    meal.nutritionRating != null && `Nutrition: ${meal.nutritionRating}`,
    meal.kidsRating      != null && `Kids: ${meal.kidsRating}`,
    meal.adultRating     != null && `Adults: ${meal.adultRating}`,
  ].filter(Boolean)

  return (
    <li className="plan-meal-item">
      <div className="plan-meal-item__info">
        <div className="plan-meal-item__title">{meal.title}</div>
        <div className="plan-meal-item__meta">
          {meal.dinnerCount} {meal.dinnerCount === 1 ? 'night' : 'nights'}
          {ratings.length > 0 && (
            <>
              {' — '}
              {ratings.map(r => <span key={r} className="rating-badge">{r}</span>)}
            </>
          )}
        </div>

        {isSwapOpen && (
          <div className="plan-meal-item__swap-panel">
            <select
              value={selectedId}
              onChange={e => setSelectedId(e.target.value)}
              style={{ padding: '0.4rem', border: '1px solid #ccc', borderRadius: '6px' }}
            >
              <option value="">— Choose a replacement —</option>
              {availableMeals.map(m => (
                <option key={m.id} value={m.id}>{m.title}</option>
              ))}
            </select>
            <button
              type="button" className="btn btn--sm"
              onClick={() => {
                if (!selectedId) return
                const newMeal = availableMeals.find(m => m.id === parseInt(selectedId))
                if (newMeal) onManualSwap(meal, [newMeal])
              }}
            >
              Swap
            </button>
            <button
              type="button" className="btn btn--sm"
              disabled={isPicking}
              onClick={() => onPickForMe(meal)}
            >
              {isPicking ? 'Picking…' : 'Pick for me'}
            </button>
            <button
              type="button" className="btn btn--sm"
              onClick={() => onOpenSwap(meal.id)}
            >
              Cancel
            </button>
          </div>
        )}
      </div>

      <div className="plan-meal-item__actions">
        <button
          type="button" className="btn btn--sm"
          onClick={() => onOpenSwap(meal.id)}
        >
          ⇄ Swap
        </button>
        <button
          type="button" className="btn btn--sm btn--danger"
          onClick={() => onRemove(meal.id)}
        >
          ×
        </button>
      </div>
    </li>
  )
}

// ── Main component ───────────────────────────────────────────────────────────

export default function PlanEditor({
  weekStartDate,
  initialMeals,
  initialMealCount,
  allMeals,
  isSaving,
  onSave,
  onDiscard,
}) {
  const [state, dispatch] = useReducer(reducer, {
    meals:               initialMeals,
    mealCount:           initialMealCount,
    manuallyExcludedIds: [],
    swapOpenId:          null,
  })

  // Track which meal slot is actively fetching a "pick for me" suggestion
  const [pickingForMealId, setPickingForMealId] = useState(null)
  const [addMealId, setAddMealId]               = useState('')

  // Meals not already in the plan — used for the add-meal dropdown and swap selects
  const currentIds    = new Set(state.meals.map(m => m.id))
  const availableMeals = allMeals.filter(m => !currentIds.has(m.id))

  // ── Regenerate ─────────────────────────────────────────────────────────────
  const regenerateMutation = useMutation({
    mutationFn: () => generateMealPlan({
      weekStartDate,
      mealCount:       state.mealCount,
      excludeMealIds:  state.manuallyExcludedIds,
    }),
    onSuccess: (data) => dispatch({ type: 'SET_MEALS', meals: data.meals }),
    onError:   ()     => alert('Failed to regenerate. Please try again.'),
  })

  // ── Pick for me ────────────────────────────────────────────────────────────
  const swapMutation = useMutation({
    mutationFn: ({ meal }) => {
      // Include the displaced meal in the exclusion list before fetching
      const excluded = state.manuallyExcludedIds.includes(meal.id)
        ? state.manuallyExcludedIds
        : [...state.manuallyExcludedIds, meal.id]
      const excludeIds = [
        ...state.meals.filter(m => m.id !== meal.id).map(m => m.id),
        ...excluded,
      ]
      return suggestSwap({ weekStartDate, swappedMealId: meal.id, excludeMealIds: excludeIds })
    },
    onSuccess: (data, { meal }) => {
      setPickingForMealId(null)
      if (data.meals?.length) {
        dispatch({ type: 'SWAP_MEAL', id: meal.id, replacements: data.meals })
      } else {
        alert('No suggestion available.')
      }
    },
    onError: () => {
      setPickingForMealId(null)
      alert('Failed to get suggestion. Please try again.')
    },
  })

  function handlePickForMe(meal) {
    setPickingForMealId(meal.id)
    swapMutation.mutate({ meal })
  }

  function handleAddMeal() {
    if (!addMealId) return
    const meal = availableMeals.find(m => m.id === parseInt(addMealId))
    if (!meal) return
    dispatch({ type: 'ADD_MEAL', meal })
    setAddMealId('')
  }

  return (
    <div className="plan-editor">
      <div className="plan-editor__controls">
        <label>
          Dinners per week:{' '}
          <input
            type="number" min="1" max="14"
            value={state.mealCount}
            onChange={e => dispatch({ type: 'SET_MEAL_COUNT', mealCount: parseInt(e.target.value) })}
            style={{ width: '60px', padding: '0.3rem 0.5rem', border: '1px solid #ccc', borderRadius: '4px' }}
          />
        </label>
        <button
          type="button" className="btn"
          onClick={() => regenerateMutation.mutate()}
          disabled={regenerateMutation.isPending}
        >
          {regenerateMutation.isPending ? 'Regenerating…' : '↺ Regenerate'}
        </button>
      </div>

      <StatusBar meals={state.meals} mealCount={state.mealCount} />

      <ul className="plan-meal-list">
        {state.meals.map(meal => (
          <MealItem
            key={meal.id}
            meal={meal}
            isSwapOpen={state.swapOpenId === meal.id}
            availableMeals={availableMeals}
            isPicking={pickingForMealId === meal.id}
            onOpenSwap={id   => dispatch({ type: 'OPEN_SWAP', id })}
            onRemove={id     => dispatch({ type: 'REMOVE_MEAL', id })}
            onManualSwap={(meal, replacements) =>
              dispatch({ type: 'SWAP_MEAL', id: meal.id, replacements })
            }
            onPickForMe={handlePickForMe}
          />
        ))}
      </ul>

      <div className="plan-editor__add-meal">
        <select
          value={addMealId}
          onChange={e => setAddMealId(e.target.value)}
          style={{ padding: '0.4rem', border: '1px solid #ccc', borderRadius: '6px' }}
        >
          <option value="">— Add a meal —</option>
          {availableMeals.map(m => (
            <option key={m.id} value={m.id}>{m.title}</option>
          ))}
        </select>
        <button type="button" className="btn" onClick={handleAddMeal}>
          Add
        </button>
      </div>

      <div className="form-actions">
        <button
          type="button" className="btn btn--primary"
          onClick={() => onSave(state.meals, state.mealCount)}
          disabled={isSaving}
        >
          {isSaving ? 'Saving…' : 'Save plan'}
        </button>
        <button type="button" className="btn" onClick={onDiscard}>
          Discard
        </button>
      </div>
    </div>
  )
}
