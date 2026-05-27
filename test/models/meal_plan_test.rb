require "test_helper"

class MealPlanTest < ActiveSupport::TestCase
  # upcoming_week_start: targets this Saturday if today IS Saturday,
  # otherwise the NEXT Saturday (current week is already underway).
  test "upcoming_week_start returns today when today is Saturday" do
    travel_to Date.new(2026, 5, 30) do # a Saturday
      assert_equal Date.new(2026, 5, 30), MealPlan.upcoming_week_start
    end
  end

  test "upcoming_week_start returns next Saturday when today is not Saturday" do
    travel_to Date.new(2026, 5, 26) do # a Tuesday
      assert_equal Date.new(2026, 5, 30), MealPlan.upcoming_week_start
    end
  end

  test "upcoming_week_start returns next Saturday when today is Friday" do
    travel_to Date.new(2026, 5, 29) do # a Friday
      assert_equal Date.new(2026, 5, 30), MealPlan.upcoming_week_start
    end
  end

  # Requirement 1: correct night count, tested with two different meal_counts.
  test "generates the correct number of dinner nights" do
    selected = MealPlan.generate(week_start_date: Date.new(2026, 6, 6), meal_count: 6)
    assert_equal 6, selected.sum(&:dinner_count)
  end

  test "respects a smaller meal_count" do
    selected = MealPlan.generate(week_start_date: Date.new(2026, 6, 6), meal_count: 3)
    assert_equal 3, selected.sum(&:dinner_count)
  end

  # Requirement 2: dinner_count fills multiple slots.
  # We exclude all non-pizza meals via a persisted prev-week plan so only
  # Pizza (dinner_count: 2) is eligible, making the selection deterministic.
  test "a multi-night meal fills the correct number of dinner slots" do
    prev_week = MealPlan.create!(week_start_date: Date.new(2026, 5, 30), meal_count: 6)
    prev_week.meals = Meal.where.not(title: "Pizza").to_a

    selected = MealPlan.generate(week_start_date: Date.new(2026, 6, 6), meal_count: 2)

    assert_equal 1, selected.length, "Expected only Pizza to be selected (1 meal record)"
    assert_equal 2, selected.sum(&:dinner_count), "Expected Pizza to fill 2 dinner nights"
  end

  # Requirement 3: last week's meals are excluded.
  # Uses the last_week fixture (2026-05-16) and generates for 2026-05-23.
  test "excludes meals from the previous week's plan" do
    last_week_meal_ids = meal_plans(:last_week).meal_ids.to_set

    selected = MealPlan.generate(week_start_date: Date.new(2026, 5, 23), meal_count: 5)

    overlap = selected.map(&:id).to_set & last_week_meal_ids
    assert overlap.empty?, "Generated plan included #{overlap.size} meal(s) from last week's plan"
  end

  # Requirement 5: variety group filtering.
  # At most one meal per variety group should appear in a generated plan.
  test "selects at most one meal per variety group" do
    # November 7, 2026 is a Saturday in cold season — enough diverse eligible meals
    selected = MealPlan.generate(week_start_date: Date.new(2026, 11, 7), meal_count: 6)

    variety_groups = selected.filter_map(&:variety_group)
    assert_equal variety_groups.uniq.length, variety_groups.length,
      "Generated plan contains multiple meals from the same variety group: #{variety_groups.tally.select { |_, n| n > 1 }.keys}"
  end

  # When the only eligible meals share a variety group, the second pass fills remaining
  # nights by relaxing the group constraint rather than leaving the plan short.
  test "falls back to variety group repeats when needed to meet meal_count" do
    # Put every cold-season-eligible non-soup meal in last week's plan so only
    # the two soups (same variety_group: "soup") remain eligible.
    oct_31 = Date.new(2026, 10, 31) # Saturday before Nov 7, cold season
    nov_7  = Date.new(2026, 11, 7)

    # "IS DISTINCT FROM" correctly includes NULL variety_group rows (unlike !=).
    non_soups = Meal.where(seasonal_preference: %w[year_round cold_months])
                    .where("variety_group IS DISTINCT FROM ?", "soup")
    prev = MealPlan.create!(week_start_date: oct_31, meal_count: non_soups.count)
    prev.meals = non_soups.to_a

    selected = MealPlan.generate(week_start_date: nov_7, meal_count: 2)

    assert_equal 2, selected.sum(&:dinner_count),
      "Expected both dinner nights filled via second-pass fallback"
    assert_equal [ "soup", "soup" ], selected.map(&:variety_group).sort,
      "Expected both selected meals to be from the soup variety group"
  end

  # Requirement 6: seasonal filtering.
  # warm_months meals (bbq_chicken, burgers) must not appear in cold-season weeks.
  test "excludes warm_months meals when generating for a cold-season week" do
    # November 7, 2026 is a Saturday in cold season (Oct–Mar)
    selected = MealPlan.generate(week_start_date: Date.new(2026, 11, 7), meal_count: 5)

    warm_ids = Meal.where(seasonal_preference: "warm_months").pluck(:id).to_set
    overlap  = selected.map(&:id).to_set & warm_ids
    assert overlap.empty?, "Generated plan included warm_months meal(s) in a cold-season week"
  end

  # cold_months meals (carrot_broccoli_soup, zuppa_toscana) must not appear in warm-season weeks.
  test "excludes cold_months meals when generating for a warm-season week" do
    # July 4, 2026 is a Saturday in warm season (Apr–Sep)
    selected = MealPlan.generate(week_start_date: Date.new(2026, 7, 4), meal_count: 5)

    cold_ids = Meal.where(seasonal_preference: "cold_months").pluck(:id).to_set
    overlap  = selected.map(&:id).to_set & cold_ids
    assert overlap.empty?, "Generated plan included cold_months meal(s) in a warm-season week"
  end

  # Requirement 4: randomness produces variation between calls.
  # We fix two different seeds and verify they yield different selections.
  test "different random seeds produce different meal selections" do
    srand(1)
    first_result = MealPlan.generate(week_start_date: Date.new(2026, 6, 6), meal_count: 5)

    srand(2)
    second_result = MealPlan.generate(week_start_date: Date.new(2026, 6, 6), meal_count: 5)

    refute_equal first_result.map(&:id).sort, second_result.map(&:id).sort,
      "Expected different random seeds to produce different meal selections"
  end
end
