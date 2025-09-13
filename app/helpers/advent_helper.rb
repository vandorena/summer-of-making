# frozen_string_literal: true

module AdventHelper
  def advent_cards_for_user(user, today = nil)
    return [] unless Flipper.enabled?(:advent_of_stickers, user)

    # yes, use the server time
    today ||= Date.current

    first_advent_day = ShopItem::AdventSticker.minimum(:unlock_on)
    return [] unless first_advent_day

    # calculate which day of the advent we're on
    advent_day = (today - first_advent_day).to_i + 1

    # create three cardd and calcualte layout!
    case advent_day
    when 1
      # Day 1: Today (left), Tomorrow (center), Day 3 (right)
      [
        advent_card_data(today, "Today", :today),
        advent_card_data(today + 1, "Tomorrow", :upcoming),
        advent_card_data(today + 2, (today + 2).strftime("%b %-d"), :upcoming)
      ]
    else
      # Day 3+: Yesterday (left), Today (center), Tomorrow (right)
      [
        advent_card_data(today - 1, "Yesterday", :past),
        advent_card_data(today, "Today", :today),
        advent_card_data(today + 1, "Tomorrow", :upcoming)
      ]
    end
  end

  private

  def advent_card_data(date, label, state)
    sticker = ShopItem::AdventSticker
      .where(unlock_on: date)
      .with_attached_image
      .with_attached_silhouette_image
      .first

    {
      sticker: sticker,
      label: label,
      state: state, # :past, :today, :upcoming
      date: date
    }
  end
end
