class Shop::TableSyncFreeStickersOrdersJob < ApplicationJob
  queue_as :literally_whenever

  def perform(*args)
    ShopOrder.mirror_free_stickers_orders_to_airtable! "s1GhHahY"
  end
end
