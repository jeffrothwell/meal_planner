require "test_helper"
require "minitest/mock"

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
  # ---------------------------------------------------------------------------

  test "generate delegates to MealPlanGenerator with the given arguments and returns its result" do
    week_start = Date.new(2026, 6, 6)
    fake_meals = [ meals(:pizza) ]
    recorded   = {}

    fake_instance = Object.new
    fake_instance.define_singleton_method(:call) { fake_meals }

    MealPlanGenerator.stub(:new, ->(**kwargs) { recorded.merge!(kwargs); fake_instance }) do
      result = MealPlan.generate(week_start_date: week_start, meal_count: 4, exclude_meal_ids: [ 99 ])
      assert_equal fake_meals, result
    end

    assert_equal week_start, recorded[:week_start_date]
    assert_equal 4,          recorded[:meal_count]
    assert_equal [ 99 ],     recorded[:exclude_meal_ids]
  end

  test "suggest_swap calls generate with meal_count: 1 and returns the first result" do
    week_start = Date.new(2026, 6, 6)
    fake_meal  = meals(:pizza)
    recorded   = {}

    MealPlan.stub(:generate, ->(**kwargs) { recorded.merge!(kwargs); [ fake_meal ] }) do
      result = MealPlan.suggest_swap(week_start_date: week_start, exclude_meal_ids: [ 99 ])
      assert_equal fake_meal, result
    end

    assert_equal week_start, recorded[:week_start_date]
    assert_equal 1,          recorded[:meal_count]
    assert_equal [ 99 ],     recorded[:exclude_meal_ids]
  end
end
