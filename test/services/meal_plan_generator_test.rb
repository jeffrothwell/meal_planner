require "test_helper"

class MealPlanGeneratorTest < ActiveSupport::TestCase
  # Convenience wrapper so tests read as `generate(...)` rather than the full constructor chain.
  def generate(**kwargs)
    MealPlanGenerator.new(**kwargs).call
  end

  # ---------------------------------------------------------------------------
  # Night count
  # ---------------------------------------------------------------------------

  test "fills the requested number of dinner nights" do
    selected = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 6)
    assert_equal 6, selected.sum(&:dinner_count)
  end

  test "respects a smaller meal_count" do
    selected = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 3)
    assert_equal 3, selected.sum(&:dinner_count)
  end

  # ---------------------------------------------------------------------------
  # Multi-night meals
  # ---------------------------------------------------------------------------

  # Pizza has dinner_count: 2. Loading every other meal into last week's plan
  # makes Pizza the only eligible meal, so the outcome is deterministic.
  test "a meal with dinner_count > 1 fills multiple dinner slots" do
    prev_week = MealPlan.create!(week_start_date: Date.new(2026, 5, 30), meal_count: 6)
    prev_week.meals = Meal.where.not(title: "Pizza").to_a

    selected = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 2)

    assert_equal 1, selected.length, "Expected only Pizza to be selected (1 meal record)"
    assert_equal 2, selected.sum(&:dinner_count), "Expected Pizza to fill 2 dinner nights"
  end

  # ---------------------------------------------------------------------------
  # Last-week exclusion
  # ---------------------------------------------------------------------------

  # The last_week fixture (2026-05-16) contains 6 meals.
  # Generating for 2026-05-23 (the following Saturday) must exclude all of them.
  test "excludes meals from the immediately preceding week's plan" do
    last_week_ids = meal_plans(:last_week).meal_ids.to_set

    selected = generate(week_start_date: Date.new(2026, 5, 23), meal_count: 5)

    overlap = selected.map(&:id).to_set & last_week_ids
    assert overlap.empty?, "Result included #{overlap.size} meal(s) from last week: #{overlap.to_a}"
  end

  # ---------------------------------------------------------------------------
  # Caller-supplied exclusions
  # ---------------------------------------------------------------------------

  test "honours caller-supplied exclude_meal_ids" do
    excluded_ids = [ meals(:pizza).id, meals(:honey_garlic_chicken).id ].to_set

    selected = generate(
      week_start_date: Date.new(2026, 6, 6),
      meal_count: 5,
      exclude_meal_ids: excluded_ids.to_a
    )

    overlap = selected.map(&:id).to_set & excluded_ids
    assert overlap.empty?, "Result included explicitly excluded meal(s): #{overlap.to_a}"
  end

  # ---------------------------------------------------------------------------
  # Variety group deduplication (first pass)
  # ---------------------------------------------------------------------------

  # November 7 is cold season — diverse enough eligible pool to fill 6 nights
  # without needing to repeat any variety group.
  test "selects at most one meal per variety group" do
    selected = generate(week_start_date: Date.new(2026, 11, 7), meal_count: 6)

    variety_groups = selected.filter_map(&:variety_group)
    duplicates = variety_groups.tally.select { |_, n| n > 1 }.keys
    assert duplicates.empty?,
      "Plan contains multiple meals from the same variety group: #{duplicates}"
  end

  # ---------------------------------------------------------------------------
  # Variety group fallback (second pass)
  # ---------------------------------------------------------------------------

  # When the only eligible meals share a variety group, the generator should
  # relax the group constraint in a second pass rather than leave nights unfilled.
  test "falls back to variety-group repeats when needed to meet meal_count" do
    oct_31 = Date.new(2026, 10, 31) # Saturday before Nov 7, cold season
    nov_7  = Date.new(2026, 11, 7)

    # Exclude every cold-season-eligible non-soup meal so only the two soups remain.
    # "IS DISTINCT FROM" correctly includes NULL variety_group rows (unlike !=).
    non_soups = Meal.where(seasonal_preference: %w[year_round cold_months])
                    .where("variety_group IS DISTINCT FROM ?", "soup")
    prev = MealPlan.create!(week_start_date: oct_31, meal_count: non_soups.count)
    prev.meals = non_soups.to_a

    selected = generate(week_start_date: nov_7, meal_count: 2)

    assert_equal 2, selected.sum(&:dinner_count),
      "Expected both dinner nights filled via second-pass fallback"
    assert_equal [ "soup", "soup" ], selected.map(&:variety_group).sort,
      "Expected both meals to be from the soup variety group"
  end

  # ---------------------------------------------------------------------------
  # Seasonal filtering
  # ---------------------------------------------------------------------------

  test "excludes warm_months meals in a cold-season week" do
    # November 7, 2026 is cold season (Oct–Mar)
    selected = generate(week_start_date: Date.new(2026, 11, 7), meal_count: 5)

    warm_ids = Meal.where(seasonal_preference: "warm_months").pluck(:id).to_set
    overlap  = selected.map(&:id).to_set & warm_ids
    assert overlap.empty?, "Result included warm_months meal(s) in a cold-season week"
  end

  test "excludes cold_months meals in a warm-season week" do
    # July 4, 2026 is warm season (Apr–Sep)
    selected = generate(week_start_date: Date.new(2026, 7, 4), meal_count: 5)

    cold_ids = Meal.where(seasonal_preference: "cold_months").pluck(:id).to_set
    overlap  = selected.map(&:id).to_set & cold_ids
    assert overlap.empty?, "Result included cold_months meal(s) in a warm-season week"
  end

  # Season boundary: April is the first warm month.
  test "treats April as warm season" do
    selected = generate(week_start_date: Date.new(2026, 4, 4), meal_count: 5)

    cold_ids = Meal.where(seasonal_preference: "cold_months").pluck(:id).to_set
    assert (selected.map(&:id).to_set & cold_ids).empty?,
      "April was incorrectly treated as cold season"
  end

  # Season boundary: September is the last warm month.
  test "treats September as warm season" do
    selected = generate(week_start_date: Date.new(2026, 9, 5), meal_count: 5)

    cold_ids = Meal.where(seasonal_preference: "cold_months").pluck(:id).to_set
    assert (selected.map(&:id).to_set & cold_ids).empty?,
      "September was incorrectly treated as cold season"
  end

  # Season boundary: October is the first cold month.
  test "treats October as cold season" do
    selected = generate(week_start_date: Date.new(2026, 10, 3), meal_count: 5)

    warm_ids = Meal.where(seasonal_preference: "warm_months").pluck(:id).to_set
    assert (selected.map(&:id).to_set & warm_ids).empty?,
      "October was incorrectly treated as warm season"
  end

  # Season boundary: March is the last cold month.
  test "treats March as cold season" do
    selected = generate(week_start_date: Date.new(2026, 3, 7), meal_count: 5)

    warm_ids = Meal.where(seasonal_preference: "warm_months").pluck(:id).to_set
    assert (selected.map(&:id).to_set & warm_ids).empty?,
      "March was incorrectly treated as warm season"
  end

  # ---------------------------------------------------------------------------
  # Inactive meals
  # ---------------------------------------------------------------------------

  # The inactive_meal fixture has perfect ratings (9/9/9) but is_active: false.
  # It must never surface in suggestions regardless of score.
  test "never suggests inactive meals" do
    selected = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 6)

    assert selected.all?(&:is_active), "Suggestion included an inactive meal"
    assert selected.none? { |m| m.id == meals(:inactive_meal).id }
  end

  # ---------------------------------------------------------------------------
  # Randomness
  # ---------------------------------------------------------------------------

  test "different random seeds produce different meal selections" do
    srand(1)
    first_result  = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 5)

    srand(2)
    second_result = generate(week_start_date: Date.new(2026, 6, 6), meal_count: 5)

    refute_equal first_result.map(&:id).sort, second_result.map(&:id).sort,
      "Expected different random seeds to produce different meal selections"
  end
end
