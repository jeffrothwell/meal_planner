# Decisions

Non-obvious choices made during development. Each entry covers the decision, the alternatives considered, and the reasoning.

---

## vite_rails over a separate frontend app

**Decision:** Use the `vite_rails` gem to serve the React bundle from within the Rails process.

**Alternatives:** A separate Create React App / Vite standalone app talking to Rails as an API server.

**Reasoning:** Single process, same origin, no CORS configuration, simpler deployment. For a personal app with one user this is clearly preferable. `importmap-rails` / `turbo` / `stimulus` were removed when React was introduced since they add complexity without benefit once React owns the UI.

---

## Saturday as week start

**Decision:** A plan's `week_start_date` must always be a Saturday. All week logic is anchored to Saturdays.

**Reasoning:** Saturday is grocery shopping day. Planning happens on Saturday morning before shopping. A unique index on `week_start_date` prevents duplicate plans for the same week.

---

## `upcoming_week_start` checks the database

**Decision:** `MealPlan.upcoming_week_start` queries the DB to check whether the current week already has a plan, rather than using day-of-week arithmetic.

**Old behaviour:** If today is Saturday → this week. Otherwise → next Saturday. This meant that on Sunday through Friday, the app always targeted next week even if the current week had no plan yet.

**New behaviour:** Find the most recent Saturday. If no plan exists for it → target that week. If a plan already exists → target the following Saturday.

**Reasoning:** The user might not always plan on Saturday. On a Sunday with no plan for the week that started yesterday, the old logic would incorrectly target the following Saturday. The DB check makes the logic independent of day-of-week.

---

## MealPlanGenerator as a service class

**Decision:** Generation logic lives in `app/services/meal_plan_generator.rb`, not in the `MealPlan` model.

**Reasoning:** The generator grew to include scoring weights, recency lookups, two-pass deduplication, and seasonal filtering. Keeping it in the model violated single-responsibility and made the model hard to read. The service is a pure computation — it never writes to the DB — which makes it easy to test in isolation.

`MealPlan.generate` and `MealPlan.suggest_swap` are thin delegators to `MealPlanGenerator.new(...).call`.

---

## Two-pass variety group deduplication

**Decision:** The generator uses two passes: first enforcing at-most-one-per-variety-group, then relaxing that constraint if the first pass can't fill all nights.

**Reasoning:** Variety groups prevent, say, two Mexican meals appearing in the same week. But if the eligible pool is small (e.g. mid-winter with cold-months filtering active and most meals used last week), enforcing the constraint would leave the plan short. The second pass ensures the plan is always as full as possible.

---

## `is_active` rather than soft delete

**Decision:** Meals have an `is_active` boolean rather than a `deleted_at` timestamp.

**Reasoning:** The use case is "temporarily retire" not "permanently delete". The user may want to reactivate a seasonal meal. Active/inactive is more semantically clear than present/deleted for this domain. An index on `is_active` makes filtering fast.

Inactive meals are excluded from:
- The suggestion pool (`MealPlanGenerator` filters `Meal.active`)
- The plan editor's `allMeals` picker (new plan: server filters; edit plan: client calls `getActiveMeals`)

Inactive meals ARE still visible in the meals index (at the bottom, dimmed) and accessible via their detail page, so the user can reactivate them.

---

## Seasonal filtering only in the generator, not the manual picker

**Decision:** `allMeals` (the manual "add a meal" dropdown in the plan editor) shows all active meals regardless of season. Seasonal filtering only applies to auto-generated suggestions.

**Reasoning:** The user explicitly asked to keep the manual picker unfiltered. They may want to override seasonal logic occasionally (e.g. make a summer BBQ meal in winter). The "Pick for me" suggestions and auto-generate do respect season because the user isn't making an explicit choice there.

---

## Per-field validation errors, not base errors

**Decision:** Rating validation errors are added per-field (`errors.add(:nutrition_rating, ...)`) not to `:base`.

**Reasoning:** Per-field errors allow the React form to highlight the specific red field and display the message inline below it. Base errors would only allow a top-level alert with no field association.

The controller transforms error keys to camelCase to match the React field names (`nutrition_rating` → `nutritionRating`).

---

## Client-side search on the meals index

**Decision:** The title search on `/meals` filters the already-loaded array in React (`Array.filter`) rather than making a new API request.

**Reasoning:** The full meals list is already in the React Query cache. For the number of meals this app will realistically have, filtering 50–100 items client-side is instant with no network overhead. If the dataset grows large enough to require pagination, this can be replaced with a server-side `?query=` param at that point.

---

## Swap suggestions auto-fetch on panel open

**Decision:** When the user clicks "⇄ Swap" on a meal, the app immediately fetches 3 suggestions from the server and shows them as clickable chips. There is no separate "Pick for me" button.

**Old behaviour:** A "Pick for me" button made a request and immediately applied the result without any choice.

**Reasoning:** The auto-fetch gives the user options without requiring an extra click, while still letting them choose which suggestion to use (or pick any meal from the dropdown instead). Selecting a chip or dropdown option swaps immediately with no separate confirm step.

---

## `wrap_parameters false` on MealPlansController

**Decision:** `MealPlansController` disables Rails' automatic JSON parameter wrapping.

**Reasoning:** `MealsController` receives `{ meal: { title: "...", ... } }` (client wraps explicitly), so Rails' wrapping under `:meal` is harmless there. But `MealPlansController` receives flat params (`week_start_date`, `meal_ids`, etc.) directly — without `wrap_parameters false`, Rails would nest everything under `:meal_plan`, breaking `params[:week_start_date]`.
