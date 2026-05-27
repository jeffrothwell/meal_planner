class MealPlan < ApplicationRecord
  has_many :meal_plan_meals
  has_many :meals, through: :meal_plan_meals

  before_validation :set_week_start_date, on: :create

  validates :week_start_date, presence: true
  validates :meal_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :week_start_date_is_saturday

  DEFAULT_MEAL_COUNT = 6

  # The Saturday that meal planning should target right now.
  # If today is Saturday (shopping day), plan for this week.
  # Any other day, the current week is already underway — plan for next Saturday.
  def self.upcoming_week_start
    today = Date.today
    today.saturday? ? today : today.next_occurring(:saturday)
  end

  # Pure computation — no DB writes, no side effects on the model.
  # Returns an array of Meal records selected for the given week, sorted by score.
  # Call as many times as needed (regenerate) before the user confirms and saves.
  # exclude_meal_ids: caller-supplied IDs to exclude on top of the automatic last-week exclusion.
  def self.generate(
    week_start_date: upcoming_week_start,
    meal_count: DEFAULT_MEAL_COUNT,
    exclude_meal_ids: []
  )
    MealPlanGenerator.new(
      week_start_date: week_start_date,
      meal_count: meal_count,
      exclude_meal_ids: exclude_meal_ids
    ).call
  end

  # Returns a single Meal suggestion for a swap slot.
  # exclude_meal_ids should include all meals currently in the plan.
  def self.suggest_swap(week_start_date: upcoming_week_start, exclude_meal_ids: [])
    generate(week_start_date: week_start_date, meal_count: 1, exclude_meal_ids: exclude_meal_ids).first
  end

  private

  def set_week_start_date
    self.week_start_date ||= self.class.upcoming_week_start
  end

  def week_start_date_is_saturday
    return if week_start_date.blank?
    errors.add(:week_start_date, "must be a Saturday") unless week_start_date.saturday?
  end
end
