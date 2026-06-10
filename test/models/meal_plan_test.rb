require "test_helper"

class MealPlanTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # upcoming_week_start
  # Targets this Saturday if today IS Saturday (shopping day),
  # otherwise the NEXT Saturday (current week is already underway).
  # ---------------------------------------------------------------------------

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

  # ---------------------------------------------------------------------------
  # Delegation to MealPlanGenerator
  # The generation logic lives in MealPlanGenerator and is tested there.
  # These tests only verify that MealPlan passes the right arguments through.
  #
  # Minitest 6 / Ruby 4 removed minitest/mock, so we use define_singleton_method
  # directly, restoring the originals in ensure blocks.
  # ---------------------------------------------------------------------------

  test "generate delegates to MealPlanGenerator with the given arguments and returns its result" do
    week_start   = Date.new(2026, 6, 6)
    fake_meals   = [ meals(:pizza) ]
    recorded     = {}

    fake_instance = Object.new
    fake_instance.define_singleton_method(:call) { fake_meals }

    original_new = MealPlanGenerator.method(:new)
    MealPlanGenerator.define_singleton_method(:new) do |**kwargs|
      recorded.merge!(kwargs)
      fake_instance
    end

    result = MealPlan.generate(week_start_date: week_start, meal_count: 4, exclude_meal_ids: [ 99 ])
    assert_equal fake_meals, result
    assert_equal week_start, recorded[:week_start_date]
    assert_equal 4,          recorded[:meal_count]
    assert_equal [ 99 ],     recorded[:exclude_meal_ids]
  ensure
    MealPlanGenerator.define_singleton_method(:new, &original_new)
  end

  test "suggest_swap delegates to generate with meal_count defaulting to 1 and returns the result array" do
    week_start = Date.new(2026, 6, 6)
    fake_meals = [ meals(:pizza) ]
    recorded   = {}

    original_generate = MealPlan.method(:generate)
    MealPlan.define_singleton_method(:generate) do |**kwargs|
      recorded.merge!(kwargs)
      fake_meals
    end

    result = MealPlan.suggest_swap(week_start_date: week_start, exclude_meal_ids: [ 99 ])
    assert_equal fake_meals, result
    assert_equal week_start, recorded[:week_start_date]
    assert_equal 1,          recorded[:meal_count]
    assert_equal [ 99 ],     recorded[:exclude_meal_ids]
  ensure
    MealPlan.define_singleton_method(:generate, &original_generate)
  end
end
