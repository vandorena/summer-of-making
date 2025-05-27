module EmotesHelper
  def parse_emotes(text)
    return text if text.blank?

    text.gsub(/:([a-zA-Z0-9_+-]+):/) do |match|
      emote_name = $1
      emote = SlackEmote.find_by_name(emote_name)

      if emote
        emote.to_html
      else
        match
      end
    end
  end

  def emote_to_html(emote_name)
    emote = SlackEmote.find_by_name(emote_name)
    emote ? emote.to_html : ":#{emote_name}:"
  end
end
