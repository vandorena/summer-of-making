# frozen_string_literal: true

# == Schema Information
#
# Table name: user_hackatime_data
#
#  id              :bigint           not null, primary key
#  data            :jsonb
#  last_updated_at :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_user_hackatime_data_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class UserHackatimeData < ApplicationRecord
  belongs_to :user

  def total_seconds_for_project(project)
    return 0 if data.blank? || data.dig("data").blank? || !data.dig("data", "projects").is_a?(Array)
    project_keys = project.hackatime_keys
    return 0 if project_keys.blank?

    data.dig("data", "projects").sum do |hackatime_project|
      if project_keys.include?(hackatime_project["name"])
        hackatime_project["total_seconds"]
      else
        0
      end
    end
  end

  def projects
    projects = data&.dig("data", "projects") || []

    projects
      .map { |project| {
        key: project["name"], # Deprecated
        name: project["name"],
        total_seconds: project["total_seconds"],
        formatted_time: project["text"]
      }}
      .reject { |p| [ "<<LAST_PROJECT>>", "Other" ].include?(p[:name]) }
      .sort_by { |p| p[:name] }
  end
end
