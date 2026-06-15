require "test_helper"

class MealTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # is_active default and scopes
  # ---------------------------------------------------------------------------

  test "new meals are active by default" do
    meal = Meal.new(title: "T", description: "D")
    assert meal.is_active, "Expected is_active to default to true"
  end

  test "Meal.active returns only active meals" do
    active_ids = Meal.active.pluck(:id).to_set
    assert_includes active_ids, meals(:pizza).id
    assert_not_includes active_ids, meals(:inactive_meal).id
  end

  test "Meal.inactive returns only inactive meals" do
    inactive_ids = Meal.inactive.pluck(:id).to_set
    assert_includes inactive_ids, meals(:inactive_meal).id
    assert_not_includes inactive_ids, meals(:pizza).id
  end

  # ---------------------------------------------------------------------------
  # Presence validations
  # ---------------------------------------------------------------------------

  test "is invalid without a title" do
    meal = Meal.new(description: "A description")
    assert_not meal.valid?
    assert_includes meal.errors[:title], "can't be blank"
  end

  test "is invalid without a description" do
    meal = Meal.new(title: "A title")
    assert_not meal.valid?
    assert_includes meal.errors[:description], "can't be blank"
  end

  # ---------------------------------------------------------------------------
  # Rating range validation (runs on both create and update)
  # ---------------------------------------------------------------------------

  test "is valid when all ratings are within 0–10" do
    meal = Meal.new(title: "T", description: "D",
                    nutrition_rating: 5, kids_rating: 0, adult_rating: 10)
    assert meal.valid?
  end

  test "is valid when ratings are nil" do
    meal = Meal.new(title: "T", description: "D")
    assert meal.valid?
  end

  test "adds an error on nutrition_rating when out of range" do
    meal = Meal.new(title: "T", description: "D", nutrition_rating: 11)
    assert_not meal.valid?
    assert_includes meal.errors[:nutrition_rating], "must be between 0 and 10"
  end

  test "adds an error on kids_rating when out of range" do
    meal = Meal.new(title: "T", description: "D", kids_rating: -1)
    assert_not meal.valid?
    assert_includes meal.errors[:kids_rating], "must be between 0 and 10"
  end

  test "adds an error on adult_rating when out of range" do
    meal = Meal.new(title: "T", description: "D", adult_rating: 99)
    assert_not meal.valid?
    assert_includes meal.errors[:adult_rating], "must be between 0 and 10"
  end

  test "reports errors on every out-of-range rating in a single validation pass" do
    meal = Meal.new(title: "T", description: "D",
                    nutrition_rating: 50, kids_rating: 50, adult_rating: 50)
    assert_not meal.valid?
    assert_includes meal.errors[:nutrition_rating], "must be between 0 and 10"
    assert_includes meal.errors[:kids_rating],      "must be between 0 and 10"
    assert_includes meal.errors[:adult_rating],     "must be between 0 and 10"
  end

  test "rating validation also runs on update" do
    meal = meals(:pizza)
    meal.nutrition_rating = 999
    assert_not meal.valid?
    assert_includes meal.errors[:nutrition_rating], "must be between 0 and 10"
  end
end
