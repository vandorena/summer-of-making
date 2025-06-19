# frozen_string_literal: true

# == Schema Information
#
# Table name: comments
#
#  id           :bigint           not null, primary key
#  rich_content :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  devlog_id    :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_comments_on_devlog_id  (devlog_id)
#  index_comments_on_user_id    (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (devlog_id => devlogs.id)
#  fk_rails_...  (user_id => users.id)
#
class Comment < ApplicationRecord
  include EmotesHelper
  include ActionView::Helpers::SanitizeHelper

  belongs_to :user
  belongs_to :devlog, counter_cache: true

  validates :rich_content, presence: true

  after_create :notify_devlog_author
  after_destroy :delete_from_airtable
  after_commit :sync_to_airtable, on: [ :create ]

  def display_content
    sanitized_content = sanitize(render_rich_content,
                                 tags: %w[a br code pre p em strong h1 h2 h3 h4 h5 h6 ul ol li blockquote span],
                                 attributes: %w[href title class target])

    parse_emotes(sanitized_content)
  end

  private

  def render_rich_content
    parsed_rich_content = JSON.parse(rich_content)

    return parsed_rich_content["content"] || "" if parsed_rich_content["type"] == "tiptap"

    parsed_rich_content.to_s
  end

  def notify_devlog_author
    return if devlog.user.slack_id.blank?

    message = "New comment on your project!:dino-bbq:\n\nCheck it out here: #{Rails.application.routes.url_helpers.project_url(
      devlog.project, host: ENV.fetch('APP_HOST', nil)
    )}"
    SendSlackDmJob.perform_later(devlog.user.slack_id, message)
  end

  def sync_to_airtable
    SyncCommentToAirtableJob.perform_later(id)
  end

  def delete_from_airtable
    DeleteCommentFromAirtableJob.perform_later(id)
  end
end
