class Meal < ApplicationRecord
  has_many :meal_plan_meals
  has_many :meal_plans, through: :meal_plan_meals

  RATING_ATTRIBUTES = %i[nutrition_rating kids_rating adult_rating]

  scope :active,   -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  # year_round: suggest any time.
  # warm_months: April–September (Spring + Summer).
  # cold_months: October–March (Fall + Winter).
  enum :seasonal_preference, {
    year_round:  "year_round",
    warm_months: "warm_months",
    cold_months: "cold_months"
  }

  SEASONAL_PREFERENCE_LABELS = {
    "year_round"  => "Year round",
    "warm_months" => "Warm months (Apr–Sep)",
    "cold_months" => "Cold months (Oct–Mar)"
  }.freeze

  validates :title, presence: true
  validates :description, presence: true
  validate :rating_validator

  def rating_validator
    RATING_ATTRIBUTES.each do |rating|
      next if send(rating).nil? || (0..10).include?(send(rating))

      errors.add(rating, "must be between 0 and 10")
    end
  end
end
