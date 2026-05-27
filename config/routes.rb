Rails.application.routes.draw do
  root "pages#home"

  resources :meals, except: [ :destroy ]

  resources :meal_plans do
    collection do
      get :generate      # AJAX — returns JSON: a fresh full-plan suggestion
      get :suggest_swap  # AJAX — returns JSON: a single meal replacement
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
