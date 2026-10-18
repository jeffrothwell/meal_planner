# Frontend

## Entry point

`app/javascript/entrypoints/application.jsx` — sets up the React root, `QueryClientProvider`, `BrowserRouter`, and all routes. This is the only place routes are declared.

## Page components

Each page component lives in `app/javascript/pages/` and maps to a React Router `<Route>`.

| File | Route(s) | Notes |
|------|----------|-------|
| `MealsPage.jsx` | `/meals` | Meal list with client-side title search |
| `MealDetailPage.jsx` | `/meals/:id` | Shows ratings, season, variety group, active status pill |
| `MealFormPage.jsx` | `/meals/new`, `/meals/:id/edit` | Shared form for create and edit |
| `MealPlansPage.jsx` | `/meal_plans` | Plan list |
| `MealPlanDetailPage.jsx` | `/meal_plans/:id` | Plan details; meal titles link to their detail pages |
| `PlanEditorPage.jsx` | `/meal_plans/new`, `/meal_plans/:id/edit` | Data/save layer; renders `<PlanEditor>` |

## Shared components

**`Layout.jsx`** — top nav with links; renders `<Outlet>` for child routes.

**`PlanEditor.jsx`** — the complex plan editing UI. Manages state with `useReducer`. Split from `PlanEditorPage` so page-level concerns (fetching, saving, routing) stay separate from UI concerns.

## Data fetching

TanStack React Query v5. All reads use `useQuery`, all writes use `useMutation`.

```js
// Read
const { data, isPending, isError } = useQuery({
  queryKey: ['meals'],
  queryFn:  getMeals,
})

// Write
const mutation = useMutation({
  mutationFn: (data) => createMeal(data),
  onSuccess:  (meal) => { queryClient.invalidateQueries(...); navigate(...) },
  onError:    (err)  => { setFieldErrors(err.data?.errors ?? {}) },
})
```

**Query keys:** `['meals']`, `['meals', id]`, `['mealPlans']`, `['mealPlans', id]`, `['newPlanData']`, `['activeMeals']`

**`staleTime: 0, gcTime: 0`** on `['newPlanData']` — forces a fresh generate every time the new-plan page mounts.

## API layer

`app/javascript/api/client.js` — thin `fetch` wrapper that:
- Sets `Accept: application/json` and `Content-Type: application/json`
- Reads and sends the Rails CSRF token
- Throws on non-2xx with `error.status` and `error.data` (parsed JSON body) attached

`app/javascript/api/meals.js` — `getMeals`, `getActiveMeals` (active-only, used by plan editor), `getMeal`, `createMeal`, `updateMeal`

`app/javascript/api/mealPlans.js` — `getMealPlans`, `getMealPlan`, `getNewPlanData`, `createMealPlan`, `updateMealPlan`, `generateMealPlan`, `suggestSwap`

**`getActiveMeals`** calls `/meals.json?active_only=true`. The server filters to active meals when this param is present. Used by `PlanEditorPage` in edit mode so inactive meals don't appear in the swap/add picker.

## Form error handling

Field-level errors flow like this:

1. Server adds per-field errors: `errors.add(:nutrition_rating, "must be between 0 and 10")`
2. Controller transforms keys to camelCase: `errors.messages.transform_keys { |k| k.to_s.camelize(:lower) }`
3. Response: `{ "errors": { "nutritionRating": ["must be between 0 and 10"] } }`
4. Client stores in `fieldErrors` state (object keyed by field name)
5. Each input has `aria-invalid={!!fieldErrors.fieldName}` — drives red border via CSS
6. `<FieldError errors={fieldErrors} field="fieldName" />` renders the message below the input
7. `handleChange` clears the error for a field as soon as the user edits it

Forms use `noValidate` to suppress browser-native HTML5 validation tooltips.

## Plan editor state (useReducer)

`PlanEditor.jsx` uses `useReducer` because the state transitions are complex and interconnected. Actions:

| Action | Effect |
|--------|--------|
| `SET_MEALS` | Replace full meal list (after regenerate), close any open swap panel |
| `SET_MEAL_COUNT` | Update the target dinner-nights count |
| `REMOVE_MEAL` | Remove a meal, add its ID to `manuallyExcludedIds` |
| `OPEN_SWAP` | Toggle a meal's swap panel open/closed |
| `CLOSE_SWAP` | Close any open swap panel |
| `SWAP_MEAL` | Replace a meal with one or more replacements, add displaced meal to `manuallyExcludedIds`, close panel |
| `ADD_MEAL` | Append a meal to the list |

**`manuallyExcludedIds`** — accumulates IDs of meals the user has removed or swapped out. Passed to the server on regenerate and swap requests so those meals don't come back as suggestions.

**Swap suggestions** are fetched automatically when a swap panel opens (`handleOpenSwap` fires `fetchSuggestionsMutation` with `mealCount: 3`). Results are stored in a `swapSuggestions` object keyed by meal ID. Selecting a suggestion chip or choosing from the dropdown immediately dispatches `SWAP_MEAL` — no separate "Swap" confirm button.

## Utilities

`app/javascript/utils/meals.js`:
- `SEASONAL_LABELS` — maps enum values to display strings
- `formatDate(dateStr)` — parses `YYYY-MM-DD` as local time (avoids UTC-offset day shift), returns e.g. `"May 16, 2026"`
- `truncate(str, max)` — truncates with ellipsis

`app/javascript/utils/mealPlans.js`:
- `formatWeekDate(dateStr)` — full month name format, e.g. `"May 30, 2026"`
