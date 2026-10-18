# Architecture

## Same-origin SPA via vite_rails

The app is a single Rails process that serves both the API and the React frontend. There is no separate frontend server in production and no CORS configuration. This is achieved with the `vite_rails` gem.

- Vite bundles the React code from `app/javascript/`
- In development, a Vite dev server runs alongside Rails (started together by `bin/dev`) and provides HMR
- In production, `vite build` outputs to `public/vite-dist/` which Rails serves statically via Propshaft

## How Rails hands off to React

Every HTML request (browser navigation, direct URL entry) ends up at `PagesController#app`, which renders `views/pages/app.html.erb` inside `views/layouts/react.html.erb`. The layout loads the Vite bundle and mounts a `<div id="root">` where React attaches.

Two routes achieve this:

```ruby
# Explicit routes also handle HTML for their paths (respond_to format.html)
resources :meals, except: [:destroy]
resources :meal_plans

# Catch-all for any other HTML request React Router should handle
get "*path", to: "pages#app", constraints: ->(req) { req.format.html? }
```

The constraint `req.format.html?` means JSON requests to unknown paths are NOT caught — they return 404 normally.

## JSON API conventions

### HTML + JSON on GET actions, JSON-only on mutations

Read actions (index, show, new) use `respond_to` to serve both:
- `format.html` → `render_react_app` (serves the React shell)
- `format.json` → `render json: ...`

Create/update actions (`create`, `update`) are JSON-only — no `respond_to` block, no HTML branch. React always calls them with `Accept: application/json`.

### Response shape

Successful responses return the resource directly or a plain hash. Failure returns:

```json
{ "errors": { "fieldName": ["message"] } }
```

Keys are **camelCase** throughout (both request and response). The controller transforms them:

```ruby
@meal.errors.messages.transform_keys { |k| k.to_s.camelize(:lower) }
```

### wrap_parameters

`MealPlansController` sets `wrap_parameters false` at the top of the class. Without this, Rails would auto-wrap the flat JSON body under a `:meal_plan` key, breaking `params[:week_start_date]` etc.

`MealsController` does NOT need this because its params arrive as `{ meal: { ... } }` — the client wraps them explicitly.

## CSRF

Rails CSRF protection is active. The React API client reads the token from the meta tag injected by `<%= csrf_meta_tags %>` in the layout and includes it on every non-GET request:

```js
// app/javascript/api/client.js
function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}
```

## Routing

React Router runs in **library mode** (`BrowserRouter` + `Routes` + `Route`), not framework mode. There is no file-based routing. All routes are declared in `app/javascript/entrypoints/application.jsx`. The root path redirects to `/meals`.

Rails routes and React routes use the same URL paths — Rails handles the initial HTML load, then React Router takes over navigation without page reloads.

## render_react_app helper

Defined in `ApplicationController`:

```ruby
def render_react_app(status: :ok)
  render "pages/app", layout: "react", status: status
end
```

Accepting a `status:` kwarg means error branches (e.g. a 404 on a resource that doesn't exist) can still serve the React shell with the correct HTTP status code.
