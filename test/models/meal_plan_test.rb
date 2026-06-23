require "test_helper"

class MealPlanTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # upcoming_week_start
  # Returns the Saturday that started the current week (or today if Saturday).
  # If a plan already exists for that week, returns the following Saturday instead.
  # ---------------------------------------------------------------------------

  test "upcoming_week_start returns the current Saturday when no plan exists for this week" do
    travel_to Date.new(2026, 6, 6) do # a Saturday, no plan in fixtures for this week
      assert_equal Date.new(2026, 6, 6), MealPlan.upcoming_week_start
    end
  end

  test "upcoming_week_start returns the most recent Saturday mid-week when no plan exists" do
    travel_to Date.new(2026, 6, 10) do # a Wednesday; current week started June 6
      assert_equal Date.new(2026, 6, 6), MealPlan.upcoming_week_start
    end
  end

  test "upcoming_week_start returns the following Saturday when a plan already exists for the current week" do
    plan = MealPlan.create!(week_start_date: Date.new(2026, 6, 6), meal_count: 6)

    travel_to Date.new(2026, 6, 8) do # a Monday; current week started June 6
      assert_equal Date.new(2026, 6, 13), MealPlan.upcoming_week_start
    end
  ensure
    plan&.destroy
  end

  test "upcoming_week_start returns the following Saturday even when today is Saturday and a plan already exists" do
    plan = MealPlan.create!(week_start_date: Date.new(2026, 6, 6), meal_count: 6)

    travel_to Date.new(2026, 6, 6) do # Saturday but the plan was already saved
      assert_equal Date.new(2026, 6, 13), MealPlan.upcoming_week_start
    end
  ensure
    plan&.destroy
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
