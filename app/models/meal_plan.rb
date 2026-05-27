class MealPlan < ApplicationRecord
  has_many :meal_plan_meals
  has_many :meals, through: :meal_plan_meals

  before_validation :set_week_start_date, on: :create

  validates :week_start_date, presence: true
  validates :meal_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validate :week_start_date_is_saturday

  DEFAULT_MEAL_COUNT = 6
  SCORING_WEIGHTS = { nutrition_rating: 0.25, kids_rating: 0.45, adult_rating: 0.30 }.freeze
  MAX_RECENCY_BONUS = 3.0
  MAX_JITTER = 2.0

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
    last_week_start = week_start_date - 7.days
    last_week_ids = find_by(week_start_date: last_week_start)&.meal_ids || []
    all_excluded = (last_week_ids + Array(exclude_meal_ids)).uniq
    seasonal_prefs = warm_season?(week_start_date) ? %w[year_round warm_months] : %w[year_round cold_months]
    eligible = Meal.where.not(id: all_excluded).where(seasonal_preference: seasonal_prefs)

    recency = recency_lookup(eligible, week_start_date)

    scored = eligible.map { |m| [m, score_meal(m, recency[m.id], week_start_date)] }
                     .sort_by { |_, s| -s }

    selected = []
    nights = 0
    scored.each do |meal, _|
      remaining = meal_count - nights
      break if remaining <= 0
      next if meal.dinner_count > remaining

      selected << meal
      nights += meal.dinner_count
    end

    selected
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

  class << self
    private

    # April (4) through September (9) = warm season.
    # October (10) through March (3)  = cold season.
    def warm_season?(date)
      date.month.between?(4, 9)
    end

    def recency_lookup(eligible, week_start_date)
      MealPlanMeal.joins(:meal_plan)
                  .where(meal_id: eligible.map(&:id))
                  .where.not(meal_plans: { week_start_date: week_start_date })
                  .group(:meal_id)
                  .maximum("meal_plans.week_start_date")
    end

    def score_meal(meal, last_used_on, week_start_date)
      base = SCORING_WEIGHTS.sum { |attr, weight| (meal.send(attr) || 0) * weight }
      recency_bonus = if last_used_on.nil?
        MAX_RECENCY_BONUS
      else
        [((week_start_date - last_used_on) / 7.0).floor * 0.5, MAX_RECENCY_BONUS].min
      end
      base + recency_bonus + (rand * MAX_JITTER)
    end
  end
end
