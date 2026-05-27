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

  # GET /meal_plans/new — no existing plan for upcoming week
  test "GET /meal_plans/new returns 200 and renders plan editor when no plan exists" do
    # Today is 2026-05-27 (Wednesday), upcoming Saturday is 2026-05-30
    # No fixture exists for 2026-05-30, so a fresh plan should be generated
    get new_meal_plan_path
    assert_response :success
    assert_select "[data-controller='plan-editor']"
    assert_no_match(/already have a meal plan/, response.body)
  end

  # GET /meal_plans/new — plan already exists for upcoming week
  test "GET /meal_plans/new shows existing-plan modal when plan already exists" do
    upcoming = MealPlan.upcoming_week_start
    plan = MealPlan.create!(week_start_date: upcoming, meal_count: 6)

    get new_meal_plan_path
    assert_response :success
    assert_match(/already have a meal plan/, response.body)
    assert_select "a[href='#{edit_meal_plan_path(plan)}']"
  ensure
    plan&.destroy
  end

  # POST /meal_plans — valid params
  test "POST /meal_plans with valid params redirects to plan show and increases count" do
    assert_difference("MealPlan.count", 1) do
      post meal_plans_path, params: {
        week_start_date: "2026-05-30",
        meal_count: "6",
        meal_ids: [ meals(:bbq_chicken).id.to_s, meals(:pizza).id.to_s ]
      }
    end
    assert_redirected_to meal_plan_path(MealPlan.last)
  end

  # POST /meal_plans — plan already exists for that week
  test "POST /meal_plans when plan already exists redirects to edit page" do
    existing = MealPlan.create!(week_start_date: "2026-05-30", meal_count: 6)

    assert_no_difference("MealPlan.count") do
      post meal_plans_path, params: {
        week_start_date: "2026-05-30",
        meal_count: "6",
        meal_ids: [ meals(:bbq_chicken).id.to_s ]
      }
    end
    assert_redirected_to edit_meal_plan_path(existing)

    existing.destroy
  end

  # GET /meal_plans/:id/edit
  test "GET /meal_plans/:id/edit returns 200" do
    get edit_meal_plan_path(meal_plans(:last_week))
    assert_response :success
  end

  # PATCH /meal_plans/:id
  test "PATCH /meal_plans/:id with valid params redirects to show" do
    plan = meal_plans(:last_week)
    patch meal_plan_path(plan), params: {
      meal_count: "5",
      meal_ids: [ meals(:bbq_chicken).id.to_s ]
    }
    assert_redirected_to meal_plan_path(plan)
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
  test "GET /meal_plans/suggest_swap returns 200 with meal JSON" do
    get suggest_swap_meal_plans_path, params: {
      week_start_date: "2026-06-06",
      exclude_meal_ids: [ meals(:bbq_chicken).id.to_s ]
    }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body.key?("meal"), "Response should have 'meal' key"
    meal = body["meal"]
    assert meal.key?("dinnerCount"), "Meal should use camelCase dinnerCount"
  end
end
