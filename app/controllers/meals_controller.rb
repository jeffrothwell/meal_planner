class MealsController < ApplicationController
  before_action :set_meal, only: [ :show, :edit, :update ]

  def index
    @meals = Meal.includes(meal_plan_meals: :meal_plan).order(updated_at: :desc)
    respond_to do |format|
      format.html { render_react_app }
      format.json { render json: @meals.map { |m| meal_json(m) } }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: meal_json(@meal) }
    end
  end

  def new
    @meal = Meal.new
  end

  def create
    @meal = Meal.new(meal_params)
    respond_to do |format|
      if @meal.save
        format.html { redirect_to @meal, notice: "Meal added." }
        format.json { render json: meal_json(@meal), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @meal.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @meal.update(meal_params)
        format.html { redirect_to @meal, notice: "Meal updated." }
        format.json { render json: meal_json(@meal) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @meal.errors.full_messages }, status: :unprocessable_entity }
      end
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
      recipeUrl:         meal.recipe_url,
      lastPlanned:       meal.meal_plan_meals
                             .max_by { |mpm| mpm.meal_plan.week_start_date }
                             &.meal_plan
                             &.week_start_date,
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
      :recipe_url
    )
  end
end
