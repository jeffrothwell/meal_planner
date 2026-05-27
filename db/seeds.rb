# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
Meal.find_or_create_by!(
  title: "Veggie Burritos",
  description: "Sweet potato, black bean and rice burritos with the usual toppings.",
  nutrition_rating: 8,
  kids_rating: 5,
  adult_rating: 7,
)
Meal.find_or_create_by!(
  title: "Pasta with Meat Sauce",
  description: "Spaghetti with a hearty meat sauce. Usually sausage or ground beef, peppers, onions",
  nutrition_rating: 5,
  kids_rating: 8,
  adult_rating: 7,
)
Meal.find_or_create_by!(
  title: "Perogies and veggies",
  description: "Perogies with a side of steamed broccoli and carrots.",
  nutrition_rating: 6,
  kids_rating: 9,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Barbeque Chicken, veggies and potatoes",
  description: "BBQ chicken (drumsticks or thighs) with a side of roasted vegetables and potatoes.",
  nutrition_rating: 8,
  kids_rating: 8,
  adult_rating: 9,
)
Meal.find_or_create_by!(
  title: "Pizza",
  description: "Pizza!",
  nutrition_rating: 6,
  kids_rating: 9,
  adult_rating: 8,
  dinner_count: 2
)
Meal.find_or_create_by!(
  title: "Honey Garlic Chicken and Rice",
  description: "Honey garlic chicken thighs with a side of rice and steamed vegetables.",
  nutrition_rating: 7,
  kids_rating: 8,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Caramelized Beef, Rice and Veggies",
  description: "Caramelized beef with a side of rice and steamed vegetables.",
  nutrition_rating: 7,
  kids_rating: 9,
  adult_rating: 9,
)
Meal.find_or_create_by!(
  title: "Shepherd's Pie",
  description: "Ground beef and vegetables topped with mashed potatoes and baked until golden.",
  nutrition_rating: 8,
  kids_rating: 8,
  adult_rating: 9,
)
Meal.find_or_create_by!(
  title: "Chicken Parmesean",
  description: "Breaded chicken breasts topped with marinara sauce and melted cheese, served on a bed of pasta.",
  nutrition_rating: 6,
  kids_rating: 9,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Burgers, fries and veggies",
  description: "Burgers, fries and veggies!",
  nutrition_rating: 5,
  kids_rating: 7,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Chicken Burgers, fries and veggies",
  description: "Chicken Burgers, fries and veggies!",
  nutrition_rating: 5,
  kids_rating: 7,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Hamburger Helper",
  description: "Hamburger Helper! The classic boxed meal - but homemade.",
  nutrition_rating: 4,
  kids_rating: 8,
  adult_rating: 7,
)
Meal.find_or_create_by!(
  title: "Beef Tacos",
  description: "Ground beef tacos with the usual toppings.",
  nutrition_rating: 6,
  kids_rating: 8,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Chicken Tacos",
  description: "Ground chicken tacos with the usual toppings.",
  nutrition_rating: 7,
  kids_rating: 8,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Carrot Broccoli Soup and Bread",
  description: "A comforting soup made with carrots and broccoli, served with a side of crusty bread.",
  nutrition_rating: 7,
  kids_rating: 7,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Zuppa Toscana and Bread",
  description: "A hearty soup made with sausage, potatoes and kale, served with a side of crusty bread.",
  nutrition_rating: 8,
  kids_rating: 7,
  adult_rating: 9,
)
Meal.find_or_create_by!(
  title: "Tuna melts and veggies",
  description: "Tuna melts with a side of steamed vegetables.",
  nutrition_rating: 5,
  kids_rating: 7,
  adult_rating: 7,
)
Meal.find_or_create_by!(
  title: "Chicken and Chorizo Paella",
  description: "A flavorful Spanish rice dish made with chicken, chorizo, and a variety of vegetables and spices.",
  nutrition_rating: 8,
  kids_rating: 7,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Chicken Quesadillas",
  description: "Grilled chicken quesadillas with melted cheese and a side of salsa and sour cream.",
  nutrition_rating: 6,
  kids_rating: 9,
  adult_rating: 8,
)
Meal.find_or_create_by!(
  title: "Greek Night!",
  description: "Chicken souvlaki, Greek potatoes,  salad and pita bread with tzatziki sauce. Opa!",
  nutrition_rating: 9,
  kids_rating: 8,
  adult_rating: 9,
)

# Set seasonal preferences — idempotent, safe to re-run.
{
  "Barbeque Chicken, veggies and potatoes" => "warm_months",
  "Burgers, fries and veggies"             => "warm_months",
  "Chicken Burgers, fries and veggies"     => "warm_months",
  "Carrot Broccoli Soup and Bread"         => "cold_months",
  "Zuppa Toscana and Bread"                => "cold_months",
}.each do |title, preference|
  Meal.where(title: title).update_all(seasonal_preference: preference)
end

# Seed meal plans for the previous 4 weeks.
# Generate oldest-first so each week's last-week exclusion builds on the one before it.
# Skips any week that already has a plan.
upcoming = MealPlan.upcoming_week_start

4.downto(1) do |weeks_ago|
  week_start = upcoming - weeks_ago.weeks

  if MealPlan.exists?(week_start_date: week_start)
    puts "  Meal plan for #{week_start.strftime('%b %-d, %Y')} already exists, skipping."
    next
  end

  meals = MealPlan.generate(week_start_date: week_start, meal_count: MealPlan::DEFAULT_MEAL_COUNT)
  plan  = MealPlan.create!(week_start_date: week_start, meal_count: MealPlan::DEFAULT_MEAL_COUNT)
  plan.meal_ids = meals.map(&:id)

  puts "  Created meal plan for #{week_start.strftime('%b %-d, %Y')}: #{meals.map(&:title).join(', ')}"
end
