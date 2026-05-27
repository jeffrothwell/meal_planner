class MealPlanGenerator
  SCORING_WEIGHTS = { nutrition_rating: 0.25, kids_rating: 0.45, adult_rating: 0.30 }.freeze
  MAX_RECENCY_BONUS = 3.0
  MAX_JITTER = 2.0

  def initialize(week_start_date:, meal_count:, exclude_meal_ids: [])
    @week_start_date  = week_start_date
    @meal_count       = meal_count
    @exclude_meal_ids = Array(exclude_meal_ids)
  end

  def call
    scored = build_scored_list

    # First pass: at most one meal per variety group.
    first_pass    = fill_nights(dedupe_variety_groups(scored), @meal_count)
    nights_filled = first_pass.sum(&:dinner_count)

    return first_pass if nights_filled >= @meal_count

    # Second pass: relax variety-group constraint to meet meal_count.
    selected_ids = first_pass.map(&:id).to_set
    leftover     = scored.reject { |meal, _| selected_ids.include?(meal.id) }
    second_pass  = fill_nights(leftover, @meal_count - nights_filled)

    first_pass + second_pass
  end

  private

  # April (4) through September (9) = warm season.
  # October (10) through March (3)  = cold season.
  def warm_season?
    @week_start_date.month.between?(4, 9)
  end

  def build_scored_list
    last_week_start = @week_start_date - 7.days
    last_week_ids   = MealPlan.find_by(week_start_date: last_week_start)&.meal_ids || []
    all_excluded    = (last_week_ids + @exclude_meal_ids).uniq

    seasonal_prefs = warm_season? ? %w[year_round warm_months] : %w[year_round cold_months]
    eligible = Meal.where.not(id: all_excluded).where(seasonal_preference: seasonal_prefs)

    recency = recency_lookup(eligible)

    eligible.map { |m| [ m, score(m, recency[m.id]) ] }
            .sort_by { |_, s| -s }
  end

  # Returns a subset of scored pairs with at most one meal per variety group.
  # Ungrouped meals (variety_group: nil) are always kept.
  # Within each group, the highest-scored meal (first in the sorted list) wins.
  def dedupe_variety_groups(scored)
    seen = Set.new
    scored.select do |meal, _|
      next true if meal.variety_group.blank?
      seen.add?(meal.variety_group) # nil (falsy) when already seen; truthy when newly added
    end
  end

  # Greedily fills dinner nights from candidates until target is reached.
  # Skips meals whose dinner_count would overshoot the remaining slots.
  def fill_nights(candidates, target)
    selected = []
    nights   = 0

    candidates.each do |meal, _|
      remaining = target - nights
      break if remaining <= 0
      next  if meal.dinner_count > remaining

      selected << meal
      nights   += meal.dinner_count
    end

    selected
  end

  # Hash of { meal_id => most_recent_week_start_date } for recency bonus calculation.
  # Excludes the current week so a plan being regenerated doesn't penalise itself.
  def recency_lookup(eligible)
    MealPlanMeal.joins(:meal_plan)
                .where(meal_id: eligible.map(&:id))
                .where.not(meal_plans: { week_start_date: @week_start_date })
                .group(:meal_id)
                .maximum("meal_plans.week_start_date")
  end

  def score(meal, last_used_on)
    base = SCORING_WEIGHTS.sum { |attr, weight| (meal.send(attr) || 0) * weight }

    recency_bonus = if last_used_on.nil?
      MAX_RECENCY_BONUS
    else
      [((@week_start_date - last_used_on) / 7.0).floor * 0.5, MAX_RECENCY_BONUS].min
    end

    base + recency_bonus + (rand * MAX_JITTER)
  end
end
