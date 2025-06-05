# == Schema Information
#
# Table name: comments
#
#  id           :bigint           not null, primary key
#  rich_content :jsonb
#  text         :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  update_id    :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_comments_on_update_id  (update_id)
#  index_comments_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (update_id => updates.id)
#  fk_rails_...  (user_id => users.id)
#
class Comment < ApplicationRecord
  include EmotesHelper
  include ActionView::Helpers::SanitizeHelper

  belongs_to :user
  belongs_to :update_record, class_name: "Update", foreign_key: "update_id"

  validates :text, presence: true, unless: :rich_content?
  validates :rich_content, presence: true, unless: :text?

  after_create :notify_update_author
  after_commit :sync_to_airtable, on: [ :create ]
  after_destroy :delete_from_airtable


  # I'm not in the mood to migrate everything to rich content, so we'll just use this for now, but eventually we'll migrate everything to rich content, or just drop the text column when we for flagship
  def display_content
    content = if rich_content.present?
      render_rich_content
    else
      text
    end

    sanitized_content = sanitize(content, tags: %w[a br code pre p em strong h1 h2 h3 h4 h5 h6 ul ol li blockquote span],
                                         attributes: %w[href title class target])

    parse_emotes(sanitized_content)
  end

  def rich_content?
    rich_content.present?
  end

  def text?
    text.present?
  end

  private

  def render_rich_content
    parsed_rich_content = JSON.parse(rich_content)

    if parsed_rich_content["type"] == "tiptap"
      return parsed_rich_content["content"] || ""
    end

    # Handling legacy format, but can't wait to ditch it!
    if parsed_rich_content["blocks"]
      return parsed_rich_content["blocks"].map do |block|
        case block["type"]
        when "paragraph"
          block.dig("data", "text")
        when "code"
          "<pre><code>#{block.dig('data', 'code')}</code></pre>"
        else
          block.dig("data", "text")
        end
      end.join("")
    end

    # Fallback for unknown formats
    parsed_rich_content.to_s
  end

  def notify_update_author
    return unless update_record.user.slack_id.present?

    message = "New comment on your project!:dino-bbq:\n\nCheck it out here: #{Rails.application.routes.url_helpers.project_url(update_record.project, host: ENV['APP_HOST'])}"
    SendSlackDmJob.perform_later(update_record.user.slack_id, message)
  end

  def sync_to_airtable
    SyncCommentToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteCommentFromAirtableJob.perform_later(id)
  end
end
