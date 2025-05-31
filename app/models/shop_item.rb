class ShopItem < ApplicationRecord
  has_one_attached :image do |attachable|
      attachable.variant :thumb, resize_to_limit: [256, 256]
    end
end
