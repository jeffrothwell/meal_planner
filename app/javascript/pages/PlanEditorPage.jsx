import React from 'react'
import { useParams, useNavigate, Navigate } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { getMealPlan, getNewPlanData, createMealPlan, updateMealPlan } from '../api/mealPlans'
import { getMeals } from '../api/meals'
import { formatWeekDate } from '../utils/mealPlans'
import PlanEditor from '../components/PlanEditor'

export default function PlanEditorPage() {
  const { id }      = useParams()
  const isEditing   = Boolean(id)
  const navigate    = useNavigate()
  const queryClient = useQueryClient()

  // ── New plan ──────────────────────────────────────────────────────────────
  const { data: newPlanData, isPending: loadingNew, isError: newError } = useQuery({
    queryKey: ['newPlanData'],
    queryFn:  getNewPlanData,
    enabled:  !isEditing,
    // Never serve stale suggestions — always generate fresh on mount
    staleTime: 0,
    gcTime:    0,
  })

  // ── Edit plan ─────────────────────────────────────────────────────────────
  const { data: existingPlan, isPending: loadingPlan } = useQuery({
    queryKey: ['mealPlans', id],
    queryFn:  () => getMealPlan(id),
    enabled:  isEditing,
  })

  const { data: allMealsForEdit, isPending: loadingMeals } = useQuery({
    queryKey:  ['meals'],
    queryFn:   getMeals,
    enabled:   isEditing,
    staleTime: 5 * 60 * 1000,
  })

  // ── Save ──────────────────────────────────────────────────────────────────
  const saveMutation = useMutation({
    mutationFn: ({ meals, mealCount }) => {
      const weekStartDate = isEditing ? existingPlan.weekStartDate : newPlanData.weekStartDate
      const payload = {
        week_start_date: weekStartDate,
        meal_count:      mealCount,
        meal_ids:        meals.map(m => m.id),
      }
      return isEditing ? updateMealPlan(id, payload) : createMealPlan(payload)
    },
    onSuccess: (plan) => {
      queryClient.invalidateQueries({ queryKey: ['mealPlans'] })
      navigate(`/meal_plans/${plan.id}`, {
        state: { notice: isEditing ? 'Plan updated.' : 'Plan saved.' },
      })
    },
  })

  // ── Loading / error guards ────────────────────────────────────────────────
  if (!isEditing && loadingNew)                    return <p>Loading…</p>
  if (isEditing  && (loadingPlan || loadingMeals)) return <p>Loading…</p>
  if (newError)                                    return <p>Failed to load plan data. Please refresh.</p>

  // If a plan already exists for the upcoming week, redirect to edit it
  if (!isEditing && newPlanData?.existingPlanId) {
    return <Navigate to={`/meal_plans/${newPlanData.existingPlanId}/edit`} replace />
  }

  const weekStartDate  = isEditing ? existingPlan.weekStartDate : newPlanData.weekStartDate
  const initialMeals   = isEditing ? existingPlan.meals         : newPlanData.suggestedMeals
  const initialCount   = isEditing ? existingPlan.mealCount     : newPlanData.mealCount
  const allMeals       = isEditing ? allMealsForEdit            : newPlanData.allMeals

  return (
    <div>
      <h1>{isEditing ? 'Edit plan' : 'Plan'} for week of {formatWeekDate(weekStartDate)}</h1>
      <PlanEditor
        weekStartDate={weekStartDate}
        initialMeals={initialMeals}
        initialMealCount={initialCount}
        allMeals={allMeals}
        isSaving={saveMutation.isPending}
        onSave={(meals, mealCount) => saveMutation.mutate({ meals, mealCount })}
        onDiscard={() => navigate(isEditing ? `/meal_plans/${id}` : '/meal_plans')}
      />
    </div>
  )
}
