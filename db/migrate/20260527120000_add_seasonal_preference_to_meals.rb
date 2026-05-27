class AddSeasonalPreferenceToMeals < ActiveRecord::Migration[8.1]
  def change
    add_column :meals, :seasonal_preference, :string, null: false, default: "year_round"
  end
end
