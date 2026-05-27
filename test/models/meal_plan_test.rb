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
