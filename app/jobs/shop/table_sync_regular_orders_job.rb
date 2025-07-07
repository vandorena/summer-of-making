class Shop::TableSyncRegularOrdersJob < ApplicationJob
  queue_as :latency_5m

  def perform(*args)
    ShopOrder.mirror_real_orders_to_airtable! "0nLBAvk7"
  end
end
