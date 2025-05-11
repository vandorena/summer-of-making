class Project < ApplicationRecord
  belongs_to :user
  has_many :updates, dependent: :destroy
  has_many :project_follows, dependent: :destroy
  has_many :followers, through: :project_follows, source: :user

  has_many :won_votes, class_name: "Vote", foreign_key: "winner_id"
  has_many :lost_votes, class_name: "Vote", foreign_key: "loser_id"

  has_many :timer_sessions

  validates :title, :description, :category, presence: true

  validates :readme_link, :demo_link, :repo_link, :banner,
    format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" },
    allow_blank: true

  validates :category, inclusion: { in: [ "Software", "Hardware", "Both Software & Hardware", "Something else" ], message: "%{value} is not a valid category" }

  after_initialize :set_default_rating, if: :new_record?

  after_commit :sync_to_airtable, on: [ :create, :update ]

  def total_votes
    won_votes.count + lost_votes.count
  end

  def won_votes_count
    won_votes.count
  end

  def lost_votes_count
    lost_votes.count
  end

  private

  def set_default_rating
    self.rating ||= 1100
  end

  def sync_to_airtable
    SyncProjectToAirtableJob.perform_later(id)
  end
end
