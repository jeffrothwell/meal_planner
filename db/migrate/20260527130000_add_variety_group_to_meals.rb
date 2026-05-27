class AddVarietyGroupToMeals < ActiveRecord::Migration[8.1]
  def change
    add_column :meals, :variety_group, :string
  end
end
