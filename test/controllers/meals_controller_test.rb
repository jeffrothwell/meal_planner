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

  test "POST /meals with valid params creates the meal and returns 201" do
    assert_difference("Meal.count", 1) do
      post meals_path, params: {
        meal: { title: "Test Meal", description: "A tasty test meal.", dinner_count: 1 }
      }, as: :json
    end
    assert_response :created
    assert_equal "Test Meal", JSON.parse(response.body)["title"]
  end

  test "POST /meals with invalid params returns 422 with field errors" do
    assert_no_difference("Meal.count") do
      post meals_path, params: {
        meal: { title: "", description: "Missing a title.", dinner_count: 1 }
      }, as: :json
    end
    assert_response :unprocessable_entity
    assert JSON.parse(response.body).key?("errors")
  end

  test "GET /meals.json response includes isActive field" do
    get meals_path, as: :json
    body = JSON.parse(response.body)
    assert body.first.key?("isActive"), "Meal JSON should include isActive"
  end

  test "GET /meals.json returns both active and inactive meals" do
    get meals_path, as: :json
    body = JSON.parse(response.body)
    ids  = body.map { |m| m["id"] }.to_set
    assert_includes ids, meals(:pizza).id
    assert_includes ids, meals(:inactive_meal).id
  end

  test "GET /meals.json with active_only=true excludes inactive meals" do
    get meals_path, params: { active_only: "true" }, as: :json
    body = JSON.parse(response.body)
    ids  = body.map { |m| m["id"] }.to_set
    assert_includes     ids, meals(:pizza).id
    assert_not_includes ids, meals(:inactive_meal).id
  end

  test "GET /meals.json orders active meals before inactive meals" do
    get meals_path, as: :json
    body          = JSON.parse(response.body)
    active_idxs   = body.each_index.select { |i|  body[i]["isActive"] }
    inactive_idxs = body.each_index.select { |i| !body[i]["isActive"] }
    assert active_idxs.max < inactive_idxs.min,
      "Expected all active meals to appear before inactive ones"
  end

  test "POST /meals can create an inactive meal" do
    post meals_path, params: {
      meal: { title: "Retired dish", description: "No longer served.", dinner_count: 1, is_active: false }
    }, as: :json
    assert_response :created
    assert_equal false, JSON.parse(response.body)["isActive"]
  end

  test "PATCH /meals/:id can deactivate a meal" do
    patch meal_path(meals(:bbq_chicken)), params: { meal: { is_active: false } }, as: :json
    assert_response :success
    assert_equal false, JSON.parse(response.body)["isActive"]
  end

  test "PATCH /meals/:id can reactivate an inactive meal" do
    patch meal_path(meals(:inactive_meal)), params: { meal: { is_active: true } }, as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["isActive"]
  end

  test "GET /meals/:id/edit returns 200" do
    get edit_meal_path(meals(:bbq_chicken))
    assert_response :success
  end

  test "PATCH /meals/:id with valid params returns 200 with updated meal" do
    patch meal_path(meals(:bbq_chicken)), params: {
      meal: { title: "Updated BBQ Chicken" }
    }, as: :json
    assert_response :success
    assert_equal "Updated BBQ Chicken", JSON.parse(response.body)["title"]
  end

  test "PATCH /meals/:id with invalid params returns 422 with field errors" do
    patch meal_path(meals(:bbq_chicken)), params: {
      meal: { title: "" }
    }, as: :json
    assert_response :unprocessable_entity
    assert JSON.parse(response.body).key?("errors")
  end
end
