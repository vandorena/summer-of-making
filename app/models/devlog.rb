# frozen_string_literal: true

# == Schema Information
#
# Table name: devlogs
#
#  id                  :bigint           not null, primary key
#  attachment          :string
#  comments_count      :integer          default(0), not null
#  hackatime_pulled_at :datetime
#  last_hackatime_time :integer
#  likes_count         :integer          default(0), not null
#  seconds_coded       :integer
#  text                :text
#  views_count         :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  project_id          :bigint           not null
#  user_id             :bigint           not null
#
# Indexes
#
#  index_devlogs_on_project_id   (project_id)
#  index_devlogs_on_user_id      (user_id)
#  index_devlogs_on_views_count  (views_count)
#
# Foreign Keys
#
#  fk_rails_...  (project_id => projects.id)
#  fk_rails_...  (user_id => users.id)
#
class Devlog < ApplicationRecord
  belongs_to :user
  belongs_to :project, counter_cache: { active: false }
  has_many :comments, -> { order(created_at: :desc) }, dependent: :destroy
  has_many :timer_sessions, dependent: :nullify
  has_many :likes, as: :likeable, dependent: :destroy
  has_one_attached :file

  attr_accessor :timer_session_id

  validates :text, presence: true
  validate :file_must_be_attached, on: %i[ create ]

  # Validates if only MD changes are made
  validate :only_formatting_changes, on: :update

  validate :updates_not_locked, on: :create
  validate :validate_timer_session_not_linked, on: :create
  validate :validate_timer_session_required, on: :create
  validate :validate_hackatime_time_since_last_update, on: :create

  after_commit :associate_timer_session, on: :create
  after_commit :notify_followers_and_stakers, on: :create

  def formatted_text
    ApplicationController.helpers.markdown(text)
  end

  def liked_by?(user)
    return false unless user

    likes.exists?(user: user)
  end

  delegate :count, to: :likes, prefix: true

  # ie. Project.first.devlogs.capped_seconds_coded
  scope :capped_seconds_coded, -> { where.not(seconds_coded: nil).sum("LEAST(seconds_coded, #{10.hours.to_i})") }

  def recalculate_seconds_coded
    # find the created_at of the devlog directly before this one
    prev_time = Devlog.where(project_id: project_id)
                        .where("created_at < ?", created_at)
                        .order(created_at: :desc)
                        .first&.created_at

    # alternatively, record from the beginning of the event
    prev_time ||= begin
      Time.use_zone("America/New_York") do
        Time.parse("2025-06-16").beginning_of_day
      end
    end

    res = user.fetch_raw_hackatime_stats(from: bounded_prev_time, to: created_at)
    begin
      data = JSON.parse(res.body)
      projects = data.dig("data", "projects")

      seconds_coded = projects
        .filter { |p| project.hackatime_project_keys.include?(p["name"]) }
        .reduce(0) { |acc, h| acc += h["total_seconds"] }

      Rails.logger.info "\tDevlog #{id} seconds coded: #{seconds_coded}"
      update!(seconds_coded:, hackatime_pulled_at: Time.now)
    rescue JSON::ParserError => e
      if res.body.strip.start_with?("Gateway") || res.body.strip =~ /gateway/i
        Rails.logger.error "Hackatime API Gateway error for Devlog #{id}: #{res.body}"
        Honeybadger.notify("Hackatime API Gateway error for Devlog #{id}: #{res.body}")
        errors.add(:base, "Hackatime server had trouble, give it another go?")
      else
        Rails.logger.error "JSON parse error for Devlog #{id}: #{e.message} | Body: #{res.body}"
        Honeybadger.notify(
          error_class: "Hackatime JSON::ParserError",
          error_message: e.message,
          context: { devlog_id: id, user_id: user_id, project_id: project_id, response_body: res.body }
        )
        errors.add(:base, "There was a problem reading your Hackatime data. Give it another go?")
      end
      false
    end
  end

  private

  def file_must_be_attached
    errors.add(:file, "must be attached") unless file.attached?
  end

  def validate_timer_session_required
    has_hackatime = project.hackatime_project_keys.present? &&
                    project.user.has_hackatime? &&
                    project.user.hackatime_stat&.has_enough_time_since_last_update?(project)

    return unless timer_session_id.blank? && !has_hackatime

    errors.add(:timer_session_id, "You need to track time with Timer Session or Hackatime")
  end

  def validate_timer_session_not_linked
    return if timer_session_id.blank?

    timer_session = TimerSession.find_by(id: timer_session_id)
    return unless timer_session && timer_session.devlog_id.present?

    errors.add(:timer_session_id, "This timer session is already linked to another update")
  end

  def validate_hackatime_time_since_last_update
    return unless project.hackatime_project_keys.present? && project.user.has_hackatime?
    return if timer_session_id.present?

    return if project.user.hackatime_stat&.has_enough_time_since_last_update?(project)

    seconds_needed = project.user.hackatime_stat&.seconds_needed_since_last_update(project) || 300
    errors.add(:base,
               "You need to spend more time on this project before posting an update. #{ActionController::Base.helpers.format_seconds(seconds_needed)} more needed since your last update.")
  end

  def associate_timer_session
    return if timer_session_id.blank?

    timer_session = project.timer_sessions.find_by(id: timer_session_id)
    return unless timer_session
    return if timer_session.devlog_id.present?

    timer_session.update(devlog: self)
  end

  def updates_not_locked
    return unless ENV["UPDATES_STATUS"] == "locked"

    errors.add(:base, "Posting updates is currently locked")
  end

  def only_formatting_changes
    return unless text_changed? && persisted?

    original_stripped = strip_formatting(text_was)
    new_stripped = strip_formatting(text)

    return unless original_stripped != new_stripped

    errors.add(:text, "You can only modify formatting (markdown, spaces, line breaks), not the content")
  end

  def strip_formatting(text)
    return "" if text.nil?

    text.gsub(/[\s\n\r\t\*\_\#\~\`\>\<\-\+\.\,\;\:\!\?\(\)\[\]\{\}]/i, "").downcase
  end

  def notify_followers_and_stakers
    NotifyProjectDevlogJob.perform_later(id)
  end
end
