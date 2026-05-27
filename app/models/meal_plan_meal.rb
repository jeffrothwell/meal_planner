class MealPlanMeal < ApplicationRecord
  belongs_to :meal
  belongs_to :meal_plan
end
