# frozen_string_literal: true

# == Schema Information
#
# Table name: slack_emotes
#
#  id             :bigint           not null, primary key
#  created_by     :string
#  is_active      :boolean          default(TRUE), not null
#  last_synced_at :datetime
#  name           :string           not null
#  url            :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  slack_id       :string           not null
#
# Indexes
#
#  index_slack_emotes_on_name      (name) UNIQUE
#  index_slack_emotes_on_slack_id  (slack_id) UNIQUE
#
class SlackEmote < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
  validates :slack_id, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

  def self.find_by_name(name)
    active.find_by(name: name.to_s.gsub(/^:/, '').gsub(/:$/, ''))
  end

  def to_html
    %(<img src="#{url}" alt=":#{name}:" class="inline-emote" style="width: 20px; height: 20px; vertical-align: middle;" />)
  end
end
