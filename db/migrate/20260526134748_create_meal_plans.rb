class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.date :week_start_date, null: false
      t.integer :meal_count, default: 6, null: false
      t.timestamps
    end

    add_index :meal_plans, :week_start_date, unique: true
  end
end
