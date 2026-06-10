import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'

import Layout from '../components/Layout'
import MealsPage from '../pages/MealsPage'
import MealDetailPage from '../pages/MealDetailPage'
import MealFormPage from '../pages/MealFormPage'
import MealPlansPage from '../pages/MealPlansPage'
import MealPlanDetailPage from '../pages/MealPlanDetailPage'
import PlanEditorPage from '../pages/PlanEditorPage'

const queryClient = new QueryClient()

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Layout />}>
            <Route index element={<Navigate to="/meals" replace />} />
            <Route path="meals" element={<MealsPage />} />
            <Route path="meals/new" element={<MealFormPage />} />
            <Route path="meals/:id" element={<MealDetailPage />} />
            <Route path="meals/:id/edit" element={<MealFormPage />} />
            <Route path="meal_plans" element={<MealPlansPage />} />
            <Route path="meal_plans/new" element={<PlanEditorPage />} />
            <Route path="meal_plans/:id" element={<MealPlanDetailPage />} />
            <Route path="meal_plans/:id/edit" element={<PlanEditorPage />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}

// Only mount when the React shell is present (pages served via pages#app).
// ERB pages don't have #root so nothing happens when they load this file.
const container = document.getElementById('root')
if (container) {
  createRoot(container).render(<App />)
}
