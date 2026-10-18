# Meal Planner — Documentation

A personal weekly meal planner for a family of four (two adults, two kids). The app helps plan dinners for the week by suggesting meals based on ratings, seasonality, and recent history, and allows the user to swap or manually adjust suggestions before saving a plan.

## Tech stack

| Layer | Technology |
|-------|-----------|
| Backend | Rails 8.1, PostgreSQL |
| Frontend | React 19, React Router v7 (library mode), TanStack React Query v5 |
| Asset pipeline | vite_rails (frontend), Propshaft (CSS only) |
| Testing | Minitest (Rails default) |

## How to run

```bash
bundle install
npm install
bin/rails db:create db:migrate db:seed
bin/dev          # starts Rails + Vite dev server together
```

The app is served at `http://localhost:3000`.

## File map

```
app/
  controllers/
    application_controller.rb   # render_react_app helper
    meals_controller.rb         # CRUD for meals
    meal_plans_controller.rb    # CRUD + generate + suggest_swap
    pages_controller.rb         # serves the React HTML shell
  models/
    meal.rb                     # validations, scopes, seasonal enum
    meal_plan.rb                # week logic, delegates to generator
    meal_plan_meal.rb           # join table
  services/
    meal_plan_generator.rb      # scoring + selection algorithm
  views/
    layouts/react.html.erb      # HTML shell: loads Vite + React
    pages/app.html.erb          # empty — just triggers the layout
  javascript/
    entrypoints/application.jsx # React root, router, query client
    components/
      Layout.jsx                # nav + <Outlet>
      PlanEditor.jsx            # plan editing UI (useReducer)
    pages/
      MealsPage.jsx
      MealDetailPage.jsx
      MealFormPage.jsx
      MealPlansPage.jsx
      MealPlanDetailPage.jsx
      PlanEditorPage.jsx
    api/
      client.js                 # fetch wrapper with CSRF + error handling
      meals.js                  # meal API functions
      mealPlans.js              # meal plan API functions
    utils/
      meals.js                  # SEASONAL_LABELS, formatDate, truncate
      mealPlans.js              # formatWeekDate
  assets/stylesheets/
    application.css             # all styles (no preprocessor)

config/routes.rb                # Rails routes
db/migrate/                     # migration history
test/
  models/
  services/
  controllers/
```

## Further reading

- [architecture.md](architecture.md) — how the frontend and backend connect
- [data-model.md](data-model.md) — domain models, business rules, and the scoring algorithm
- [frontend.md](frontend.md) — React patterns and conventions used throughout the app
- [decisions.md](decisions.md) — non-obvious decisions and the reasoning behind them
