# Data Model

## Tables

### `meals`

The core record. Each row is one meal that can be planned.

| Column | Type | Notes |
|--------|------|-------|
| `title` | string | required |
| `description` | string | required |
| `nutrition_rating` | integer | 0–10, nullable |
| `kids_rating` | integer | 0–10, nullable |
| `adult_rating` | integer | 0–10, nullable |
| `dinner_count` | integer | nights this meal covers (default 1; Pizza = 2) |
| `seasonal_preference` | string (enum) | `year_round`, `warm_months`, `cold_months` |
| `variety_group` | string | nullable; meals in the same group won't both appear in one week's suggestions |
| `recipe_url` | string | nullable |
| `is_active` | boolean | default true; inactive meals are hidden from suggestions and the plan editor picker |

**Scopes:** `Meal.active`, `Meal.inactive`

**Seasonal preference:**
- `year_round` — suggested any time
- `warm_months` — April through September only
- `cold_months` — October through March only

**Nil ratings** are treated as 0 in scoring. A meal with no ratings can still be suggested but will score lower than rated meals.

---

### `meal_plans`

One plan per week. The week always starts on a Saturday (grocery shopping day).

| Column | Type | Notes |
|--------|------|-------|
| `week_start_date` | date | must be a Saturday; set automatically if blank |
| `meal_count` | integer | target number of dinner nights for the week |

A `week_start_date` uniqueness constraint prevents two plans for the same week.

**`MealPlan.upcoming_week_start`**

This is the key method for determining which week to plan for. Algorithm:

1. Find `current_week` — the most recent Saturday (today if Saturday, otherwise `today.prev_occurring(:saturday)`)
2. If a plan **already exists** for `current_week` → return `current_week + 7` (next Saturday)
3. If **no plan exists** for `current_week` → return `current_week` (plan for this week)

This means on any day of the week, if you haven't made a plan for the current week yet, the app will target the current week. Once a plan exists, it targets the following week.

---

### `meal_plan_meals`

Join table between `meal_plans` and `meals`. A meal can appear in multiple plans, and a plan has many meals.

---

## MealPlanGenerator service

`app/services/meal_plan_generator.rb`

Called via `MealPlan.generate(...)` and `MealPlan.suggest_swap(...)`. Never writes to the database — pure computation.

### Inputs

- `week_start_date` — the Saturday the plan starts
- `meal_count` — total dinner nights to fill
- `exclude_meal_ids` — caller-supplied IDs to exclude on top of automatic exclusions

### Eligible pool

Filters to active meals only, excluding:
- Meals from the **immediately preceding week** (automatic, to avoid repeats week-over-week)
- `exclude_meal_ids` (caller-supplied — used for swap exclusions, manually removed meals)
- Meals whose `seasonal_preference` doesn't match the current season (warm or cold)

### Scoring

Each eligible meal gets a score:

```
score = base + recency_bonus + jitter

base          = (nutrition_rating * 0.25) + (kids_rating * 0.45) + (adult_rating * 0.30)
                nil ratings treated as 0

recency_bonus = min(weeks_since_last_use * 0.5, 3.0)
                3.0 for a meal never used before (MAX_RECENCY_BONUS)

jitter        = rand * 2.0   (MAX_JITTER — adds randomness so the same plan
                              isn't generated every time)
```

Kids' rating has the highest weight (0.45) — this is a family meal planner.

### Two-pass selection

**First pass** — variety-group deduplication: the highest-scoring meal from each variety group is kept; all others in that group are removed. Ungrouped meals are always kept. `fill_nights` then greedily selects from this deduplicated list until `meal_count` nights are filled.

**Second pass** — if the first pass couldn't fill all nights (e.g. not enough variety groups), the constraint is relaxed and `fill_nights` is called again on the remaining candidates to top up.

**`fill_nights(candidates, target)`** — greedily iterates the scored list in score order. Skips any meal whose `dinner_count` would overshoot the remaining nights. Stops when target is reached.

### Suggest swap

`MealPlan.suggest_swap` is an alias for `generate` with different exclusions. The controller passes `meal_count` explicitly — the UI currently requests 3 suggestions for the swap chip picker.
