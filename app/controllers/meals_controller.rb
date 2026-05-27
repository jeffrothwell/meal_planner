class MealsController < ApplicationController
  before_action :set_meal, only: [ :show, :edit, :update ]

  def index
    @meals = Meal.includes(meal_plan_meals: :meal_plan).order(updated_at: :desc)
  end

  def show
  end

  def new
    @meal = Meal.new
  end

  def create
    @meal = Meal.new(meal_params)
    if @meal.save
      redirect_to @meal, notice: "Meal added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @meal.update(meal_params)
      redirect_to @meal, notice: "Meal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_meal
    @meal = Meal.find(params[:id])
  end

  def meal_params
    params.require(:meal).permit(
      :title,
      :description,
      :nutrition_rating,
      :kids_rating,
      :adult_rating,
      :dinner_count,
      :recipe_url
    )
  end
end
