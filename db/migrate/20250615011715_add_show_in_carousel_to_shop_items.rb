class AddShowInCarouselToShopItems < ActiveRecord::Migration[8.0]
  def change
    add_column :shop_items, :show_in_carousel, :boolean
  end
end
