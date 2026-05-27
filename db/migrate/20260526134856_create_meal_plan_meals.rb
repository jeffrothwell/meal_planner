class CreateMealPlanMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plan_meals do |t|
      t.references :meal, null: false, foreign_key: true, index: false
      t.references :meal_plan, null: false, foreign_key: true, index: false
      t.timestamps
    end

    add_index :meal_plan_meals, :meal_id
    add_index :meal_plan_meals, :meal_plan_id
    add_index :meal_plan_meals, [:meal_id, :meal_plan_id], unique: true
  end
end
