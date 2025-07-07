# frozen_string_literal: true

# thanks toshit, you ruined the fun
namespace :comments do
  desc "unfun all the comments"
  task convert_to_plain_text: :environment do
    require "json"
    Comment.find_each do |comment|
      begin
        data = comment.rich_content.is_a?(String) ? JSON.parse(comment.rich_content) : comment.rich_content
        plain =
          if data.is_a?(Hash) && data["content"].present?
            ActionView::Base.full_sanitizer.sanitize(data["content"].to_s)
          else
            ActionView::Base.full_sanitizer.sanitize(comment.rich_content.to_s)
          end
        comment.update_columns(content: plain)
        puts "1984ed ##{comment.id}"
      rescue => e
        puts "couldnt 1984 comment ##{comment.id}: #{e.message}"
      end
    end
    puts "fin"
  end
end
