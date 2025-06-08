class UpdateShopItemsHackerScoreToPercentage < ActiveRecord::Migration[8.0]
  def change
    change_column :shop_items, :hacker_score, :integer, default: 0, using: "CASE WHEN hacker_score ~ '^[0-9]+$' THEN hacker_score::integer ELSE 0 END"
    add_check_constraint :shop_items, "hacker_score >= 0 AND hacker_score <= 100", name: "hacker_score_percentage_check"
  end
end
