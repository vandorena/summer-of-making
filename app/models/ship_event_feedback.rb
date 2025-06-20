class ShipEventFeedback < ApplicationRecord
  belongs_to :ship_event
  has_one_attached :demo, dependent: :destroy
end
