import { get, post, patch } from './client'

export const getMeals  = ()           => get('/meals.json')
export const getMeal   = (id)         => get(`/meals/${id}.json`)
export const createMeal = (data)      => post('/meals.json', { meal: data })
export const updateMeal = (id, data)  => patch(`/meals/${id}.json`, { meal: data })
