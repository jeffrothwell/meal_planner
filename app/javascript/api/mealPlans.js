import { get, post, patch } from './client'

export const getMealPlans   = ()          => get('/meal_plans.json')
export const getMealPlan    = (id)        => get(`/meal_plans/${id}.json`)
export const getNewPlanData = ()          => get('/meal_plans/new.json')
export const createMealPlan = (data)     => post('/meal_plans.json', data)
export const updateMealPlan = (id, data) => patch(`/meal_plans/${id}.json`, data)

export function generateMealPlan({ weekStartDate, mealCount, excludeMealIds = [] }) {
  const params = new URLSearchParams()
  params.set('week_start_date', weekStartDate)
  params.set('meal_count', mealCount)
  excludeMealIds.forEach(id => params.append('exclude_meal_ids[]', id))
  return get(`/meal_plans/generate?${params}`)
}

export function suggestSwap({ weekStartDate, swappedMealId, excludeMealIds = [] }) {
  const params = new URLSearchParams()
  params.set('week_start_date', weekStartDate)
  params.set('swapped_meal_id', swappedMealId)
  excludeMealIds.forEach(id => params.append('exclude_meal_ids[]', id))
  return get(`/meal_plans/suggest_swap?${params}`)
}
