class MealsController < ApplicationController
  before_action :set_meal, only: [ :show, :edit, :update ]

  def index
    base   = params[:active_only] == "true" ? Meal.active : Meal.all
    @meals = base.includes(meal_plan_meals: :meal_plan).order(is_active: :desc, updated_at: :desc)
    respond_to do |format|
      format.html { render_react_app }
      format.json { render json: @meals.map { |m| meal_json(m) } }
    end
  end

  def show
    respond_to do |format|
      format.html { render_react_app }
      format.json { render json: meal_json(@meal) }
    end
  end

  def new
    render_react_app
  end

  def create
    @meal = Meal.new(meal_params)
    if @meal.save
      render json: meal_json(@meal), status: :created
    else
      render json: { errors: @meal.errors.messages.transform_keys { |k| k.to_s.camelize(:lower) } },
             status: :unprocessable_entity
    end
  end

  def edit
    render_react_app
  end

  def update
    if @meal.update(meal_params)
      render json: meal_json(@meal)
    else
      render json: { errors: @meal.errors.messages.transform_keys { |k| k.to_s.camelize(:lower) } },
             status: :unprocessable_entity
    end
  end

  private

  def set_meal
    @meal = Meal.includes(meal_plan_meals: :meal_plan).find(params[:id])
  end

  def meal_json(meal)
    {
      id:                meal.id,
      title:             meal.title,
      description:       meal.description,
      nutritionRating:   meal.nutrition_rating,
      kidsRating:        meal.kids_rating,
      adultRating:       meal.adult_rating,
      dinnerCount:       meal.dinner_count,
      seasonalPreference: meal.seasonal_preference,
      varietyGroup:      meal.variety_group,
      isActive:          meal.is_active,
      recipeUrl:         meal.recipe_url,
      lastPlanned:       meal.meal_plan_meals
                             .max_by { |mpm| mpm.meal_plan.week_start_date }
                             &.meal_plan
                             &.week_start_date
    }
  end

  def meal_params
    params.require(:meal).permit(
      :title,
      :description,
      :nutrition_rating,
      :kids_rating,
      :adult_rating,
      :dinner_count,
      :seasonal_preference,
      :variety_group,
      :recipe_url,
      :is_active
    )
  end
end
