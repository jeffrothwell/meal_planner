class AddIsActiveToMeals < ActiveRecord::Migration[8.1]
  def change
    add_column :meals, :is_active, :boolean, default: true, null: false
    add_index  :meals, :is_active
  end
end
