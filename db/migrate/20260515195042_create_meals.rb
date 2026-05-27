class CreateMeals < ActiveRecord::Migration[8.1]
  def change
    create_table :meals do |t|
      t.string :title, null: false
      t.string :description, null: false
      t.integer :nutrition_rating, limit: 2
      t.integer :kids_rating, limit: 2
      t.integer :adult_rating, limit: 2
      t.string :recipe_url
      t.integer :dinner_count, default: 1, null: false
      t.timestamps
    end

    add_index :meals, :title, unique: true
  end
end
