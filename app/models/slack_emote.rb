class SlackEmote < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
  validates :slack_id, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

  def self.find_by_name(name)
    active.find_by(name: name.to_s.gsub(/^:/, "").gsub(/:$/, ""))
  end

  def to_html
    %(<img src="#{url}" alt=":#{name}:" class="inline-emote" style="width: 20px; height: 20px; vertical-align: middle;" />)
  end
end
