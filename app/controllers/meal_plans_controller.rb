class MealPlansController < ApplicationController
  before_action :set_plan, only: [ :show, :edit, :update ]

  # Disable Rails' automatic JSON param wrapping so that flat params like
  # :week_start_date and :meal_ids are accessible directly on `params`.
  wrap_parameters false

  def index
    @plans = MealPlan.includes(:meals).order(week_start_date: :desc)
    respond_to do |format|
      format.html { render_react_app }
      format.json { render json: @plans.map { |p| plan_json(p) } }
    end
  end

  def show
    respond_to do |format|
      format.html { render_react_app }
      format.json { render json: plan_json(@plan) }
    end
  end

  def new
    week_start_date = MealPlan.upcoming_week_start
    existing        = MealPlan.find_by(week_start_date: week_start_date)

    respond_to do |format|
      format.html { render_react_app }
      format.json do
        if existing
          render json: { existingPlanId: existing.id }
        else
          meal_count     = MealPlan::DEFAULT_MEAL_COUNT
          suggested      = MealPlan.generate(week_start_date: week_start_date, meal_count: meal_count)
          render json: {
            weekStartDate:  week_start_date,
            existingPlanId: nil,
            mealCount:      meal_count,
            suggestedMeals: suggested.map { |m| meal_json(m) },
            allMeals:       Meal.order(:title).map { |m| meal_json(m) }
          }
        end
      end
    end
  end

  def create
    week_start_date = params[:week_start_date]
    meal_count      = params[:meal_count].to_i
    meal_ids        = params[:meal_ids]&.map(&:to_i) || []

    respond_to do |format|
      begin
        plan = MealPlan.create!(week_start_date: week_start_date, meal_count: meal_count)
        plan.meal_ids = meal_ids
        format.html { redirect_to meal_plan_path(plan) }
        format.json { render json: plan_json(MealPlan.includes(:meals).find(plan.id)), status: :created }
      rescue ActiveRecord::RecordNotUnique
        existing = MealPlan.find_by!(week_start_date: week_start_date)
        format.html { redirect_to edit_meal_plan_path(existing) }
        format.json { render json: { error: "A plan already exists for this week", existingPlanId: existing.id }, status: :conflict }
      end
    end
  end

  def edit
    render_react_app
  end

  def update
    meal_count = params[:meal_count].to_i
    meal_ids   = params[:meal_ids]&.map(&:to_i) || []

    @plan.update!(meal_count: meal_count)
    @plan.meal_ids = meal_ids

    respond_to do |format|
      format.html { redirect_to meal_plan_path(@plan) }
      format.json { render json: plan_json(MealPlan.includes(:meals).find(@plan.id)) }
    end
  end

  def generate
    week_start_date  = Date.parse(params[:week_start_date])
    meal_count       = params[:meal_count].to_i
    exclude_meal_ids = Array(params[:exclude_meal_ids]).map(&:to_i)

    meals = MealPlan.generate(
      week_start_date:  week_start_date,
      meal_count:       meal_count,
      exclude_meal_ids: exclude_meal_ids
    )

    render json: { meals: meals.map { |m| meal_json(m) } }
  end

  def suggest_swap
    week_start_date  = Date.parse(params[:week_start_date])
    exclude_meal_ids = Array(params[:exclude_meal_ids]).map(&:to_i)
    swapped_meal     = Meal.find_by(id: params[:swapped_meal_id])
    dinner_count     = swapped_meal&.dinner_count || 1

    meals = MealPlan.suggest_swap(
      week_start_date:  week_start_date,
      meal_count:       dinner_count,
      exclude_meal_ids: exclude_meal_ids
    )

    render json: { meals: meals.map { |m| meal_json(m) } }
  end

  private

  def set_plan
    @plan = MealPlan.includes(:meals).find(params[:id])
  end

  def plan_json(plan)
    {
      id:            plan.id,
      weekStartDate: plan.week_start_date,
      mealCount:     plan.meal_count,
      meals:         plan.meals.map { |m| meal_json(m) }
    }
  end

  def meal_json(meal)
    {
      id:              meal.id,
      title:           meal.title,
      description:     meal.description,
      dinnerCount:     meal.dinner_count,
      nutritionRating: meal.nutrition_rating,
      kidsRating:      meal.kids_rating,
      adultRating:     meal.adult_rating
    }
  end
end
