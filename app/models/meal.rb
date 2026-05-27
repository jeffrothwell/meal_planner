class Meal < ApplicationRecord
  has_many :meal_plan_meals
  has_many :meal_plans, through: :meal_plan_meals

  RATING_ATTRIBUTES = %i[nutrition_rating kids_rating adult_rating]

  validates :title, presence: true
  validates :description, presence: true
  validate :rating_validator, on: :create

  def rating_validator
    RATING_ATTRIBUTES.each do |rating|
      return if send(rating).nil? || (0..10).include?(send(rating))

      errors.add(:base, "Rating must be between 0 and 10")
    end
  end
end
