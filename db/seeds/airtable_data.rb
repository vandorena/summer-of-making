# frozen_string_literal: true

require 'net/http'
require 'json'

# Airtable data import
puts "Loading Airtable data..."

airtable_key = ENV['HIGHSEAS_AIRTABLE_KEY']
if airtable_key.blank?
  puts "⚠️  HIGHSEAS_AIRTABLE_KEY not set, skipping Airtable import"
  return
end

begin
  # Airtable API configuration
  app_id = 'appTeNFYcUiYfGcR6'
  table_id = 'tblGChU9vC3QvswAV'

  uri = URI("https://api.airtable.com/v0/#{app_id}/#{table_id}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{airtable_key}"

  response = http.request(request)

  if response.code == '200'
    data = JSON.parse(response.body)
    records = data['records']

    puts "Found #{records.count} records in Airtable"

    # Show available fields from first record for debugging
    if records.any?
    puts "Available fields in first record: #{records.first['fields'].keys.inspect}"
    end

    records.each do |record|
    fields = record['fields']

    name_field = fields['Name'] || fields['name'] || fields['Title'] || fields['title'] || fields['Item Name']

    unless name_field.present?
      puts "  ⚠️  Skipping record - no name field found"
        next
    end

      item_type = if fields['agh_skus'].present?
                    'ShopItem::WarehouseItem'
      elsif fields['hcb_grant_merchants'].present? || fields['hcb_grant_amount_cents'].present?
                    'ShopItem::HCBGrant'
      elsif fields['hq_mail_item_description'].present?
                    'ShopItem::HQMailItem'
      elsif [ 'third_party_physical', 'special_fulfillment' ].include?(fields['fulfillment_type'])
                    'ShopItem::SpecialFulfillmentItem'
      else
                    puts "  ❌ ERROR: Cannot determine type for #{name_field} - no identifying fields found"
                    next
      end

      existing_item = ShopItem.find_by(name: name_field)
      if existing_item
        puts "  ⏭️  Skipped existing: #{existing_item.name}"
        next
      end

      shop_item = ShopItem.create(name: name_field) do |item|
        item.type = item_type
        item.description = fields['subtitle'] # airtable subtitle -> db description
        item.internal_description = fields['description'] # airtable description -> internal_description
        item.cost = fields['doubloons_estimated']&.to_f || 0
        item.actual_irl_fr_cost = fields['unit_cost']&.to_f || fields['fair_market_value']&.to_f || 0
        item.hacker_score = fields['hacker_score']&.to_s || '0'
        item.requires_black_market = false

        # Set type-specific fields
        if item_type == 'ShopItem::WarehouseItem' && fields['agh_skus'].present?
          begin
            skus = JSON.parse(fields['agh_skus'] || '[]')
            item.agh_contents = {
              skus: skus,
              image_url: fields['image_url'],
              identifier: fields['identifier'],
              needs_address: fields['needs_addy'] || false,
              customs_likely: fields['customs_likely'] || false
            }
          rescue JSON::ParserError
            item.agh_contents = nil
          end
        elsif item_type == 'ShopItem::HCBGrant'
          item.hcb_merchant_lock = fields['hcb_grant_merchants']
        end
      end

      if shop_item.persisted?
        puts "  ✓ Created: #{shop_item.name}"
      else
        puts "  ❌ Failed to save: #{shop_item.name} - #{shop_item.errors.full_messages.join(', ')}"
      end
    end

    puts "Airtable import completed!"

  else
    puts "❌ Failed to fetch Airtable data: #{response.code} #{response.message}"
  end

rescue => e
  puts "❌ Error importing Airtable data: #{e.message}"
end
