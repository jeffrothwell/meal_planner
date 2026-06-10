import React from 'react'
import { Link, Outlet } from 'react-router-dom'

export default function Layout() {
  return (
    <>
      <nav className="app-nav">
        <span className="app-nav__brand">
          <Link to="/">🍽 Meal Planner</Link>
        </span>
        <span className="app-nav__links">
          <Link to="/meals">Meals</Link>
          <Link to="/meal_plans">Plans</Link>
          <Link to="/meal_plans/new" className="app-nav__cta">Plan next week →</Link>
        </span>
      </nav>
      <main className="app-main">
        <Outlet />
      </main>
    </>
  )
}
