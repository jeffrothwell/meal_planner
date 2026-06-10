Rails.application.routes.draw do
  root "pages#app"

  resources :meals, except: [ :destroy ]

  resources :meal_plans do
    collection do
      get :generate      # AJAX — returns JSON: a fresh full-plan suggestion
      get :suggest_swap  # AJAX — returns JSON: a single meal replacement
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Hand all remaining HTML requests to the React app.
  # JSON requests are still handled by the controllers above.
  # As pages are migrated in Phase 4, the specific HTML routes above will be
  # removed one by one and this catch-all will take over for those paths.
  get "*path", to: "pages#app", constraints: ->(req) { req.format.html? }
end
