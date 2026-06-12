require "test_helper"

class MealPlansControllerTest < ActionDispatch::IntegrationTest
  fixtures :all

  # GET /meal_plans
  test "GET /meal_plans returns 200" do
    get meal_plans_path
    assert_response :success
  end

  # GET /meal_plans/:id
  test "GET /meal_plans/:id returns 200" do
    get meal_plan_path(meal_plans(:last_week))
    assert_response :success
  end

  # GET /meal_plans/new — HTML serves the React shell
  test "GET /meal_plans/new returns 200" do
    get new_meal_plan_path
    assert_response :success
    assert_select "#root"
  end

  # GET /meal_plans/new — JSON returns week date, suggestions, and all meals
  test "GET /meal_plans/new as JSON returns weekStartDate and suggestedMeals" do
    get new_meal_plan_path, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("weekStartDate"),  "Should include weekStartDate"
    assert body.key?("suggestedMeals"), "Should include suggestedMeals"
    assert body.key?("allMeals"),       "Should include allMeals"
    assert_nil body["existingPlanId"],  "Should have no existingPlanId when no plan exists"
  end

  # GET /meal_plans/new — JSON returns existingPlanId when a plan already exists
  test "GET /meal_plans/new as JSON returns existingPlanId when plan already exists" do
    upcoming = MealPlan.upcoming_week_start
    plan = MealPlan.create!(week_start_date: upcoming, meal_count: 6)

    get new_meal_plan_path, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal plan.id, body["existingPlanId"]
  ensure
    plan&.destroy
  end

  # POST /meal_plans — valid params
  test "POST /meal_plans with valid params creates plan and returns 201" do
    assert_difference("MealPlan.count", 1) do
      post meal_plans_path, params: {
        week_start_date: "2026-05-30",
        meal_count: 6,
        meal_ids: [ meals(:bbq_chicken).id, meals(:pizza).id ]
      }, as: :json
    end
    assert_response :created
  end

  # POST /meal_plans — plan already exists for that week
  test "POST /meal_plans when plan already exists returns 409 conflict" do
    existing = MealPlan.create!(week_start_date: "2026-05-30", meal_count: 6)

    assert_no_difference("MealPlan.count") do
      post meal_plans_path, params: {
        week_start_date: "2026-05-30",
        meal_count: 6,
        meal_ids: [ meals(:bbq_chicken).id ]
      }, as: :json
    end
    assert_response :conflict
    assert_equal existing.id, JSON.parse(response.body)["existingPlanId"]

    existing.destroy
  end

  # GET /meal_plans/:id/edit
  test "GET /meal_plans/:id/edit returns 200" do
    get edit_meal_plan_path(meal_plans(:last_week))
    assert_response :success
  end

  # PATCH /meal_plans/:id
  test "PATCH /meal_plans/:id with valid params returns 200 with updated plan" do
    plan = meal_plans(:last_week)
    patch meal_plan_path(plan), params: {
      meal_count: 5,
      meal_ids: [ meals(:bbq_chicken).id ]
    }, as: :json
    assert_response :success
    plan.reload
    assert_equal 5, plan.meal_count
    assert_equal [ meals(:bbq_chicken).id ], plan.meal_ids
  end

  # GET /meal_plans/generate
  test "GET /meal_plans/generate returns 200 with meals JSON" do
    get generate_meal_plans_path, params: {
      week_start_date: "2026-06-06",
      meal_count: "3"
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("meals"), "Response should have 'meals' key"
    assert_kind_of Array, body["meals"]
    first = body["meals"].first
    assert first.key?("dinnerCount"), "Meal should use camelCase dinnerCount"
    assert first.key?("nutritionRating"), "Meal should use camelCase nutritionRating"
  end

  # GET /meal_plans/suggest_swap
  test "GET /meal_plans/suggest_swap returns 200 with meals array JSON" do
    get suggest_swap_meal_plans_path, params: {
      week_start_date: "2026-06-06",
      swapped_meal_id: meals(:pizza).id.to_s,
      exclude_meal_ids: [ meals(:bbq_chicken).id.to_s ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("meals"), "Response should have 'meals' key"
    assert_kind_of Array, body["meals"]
    assert body["meals"].first.key?("dinnerCount"), "Meal should use camelCase dinnerCount"
  end
end
