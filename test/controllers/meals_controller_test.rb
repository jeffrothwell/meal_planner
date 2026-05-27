require "test_helper"

class MealsControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  test "GET /meals returns 200" do
    get meals_path
    assert_response :success
  end

  test "GET /meals/:id returns 200" do
    get meal_path(meals(:bbq_chicken))
    assert_response :success
  end

  test "GET /meals/new returns 200" do
    get new_meal_path
    assert_response :success
  end

  test "POST /meals with valid params redirects to meal show and increases meal count" do
    assert_difference("Meal.count", 1) do
      post meals_path, params: {
        meal: {
          title: "Test Meal",
          description: "A tasty test meal.",
          dinner_count: 1
        }
      }
    end
    assert_redirected_to meal_path(Meal.last)
  end

  test "POST /meals with invalid params returns 422 and renders new" do
    assert_no_difference("Meal.count") do
      post meals_path, params: {
        meal: {
          title: "",
          description: "Missing a title.",
          dinner_count: 1
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "GET /meals/:id/edit returns 200" do
    get edit_meal_path(meals(:bbq_chicken))
    assert_response :success
  end

  test "PATCH /meals/:id with valid params redirects to meal show" do
    patch meal_path(meals(:bbq_chicken)), params: {
      meal: { title: "Updated BBQ Chicken" }
    }
    assert_redirected_to meal_path(meals(:bbq_chicken))
  end

  test "PATCH /meals/:id with invalid params returns 422 and renders edit" do
    patch meal_path(meals(:bbq_chicken)), params: {
      meal: { title: "" }
    }
    assert_response :unprocessable_entity
  end
end
