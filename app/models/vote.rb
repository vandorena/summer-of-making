# frozen_string_literal: true

# == Schema Information
#
# Table name: votes
#
#  id                   :bigint           not null, primary key
#  explanation          :text             not null
#  invalid_reason       :text
#  loser_demo_opened    :boolean          default(FALSE)
#  loser_readme_opened  :boolean          default(FALSE)
#  loser_repo_opened    :boolean          default(FALSE)
#  marked_invalid_at    :datetime
#  music_played         :boolean
#  status               :string           default("active"), not null
#  time_spent_voting_ms :integer
#  vote_number          :integer
#  winner_demo_opened   :boolean          default(FALSE)
#  winner_readme_opened :boolean          default(FALSE)
#  winner_repo_opened   :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  loser_id             :bigint
#  marked_invalid_by_id :bigint
#  user_id              :bigint           not null
#  winning_project_id   :bigint
#
# Indexes
#
#  index_votes_on_loser_id                        (loser_id)
#  index_votes_on_marked_invalid_at               (marked_invalid_at)
#  index_votes_on_marked_invalid_by_id            (marked_invalid_by_id)
#  index_votes_on_status                          (status)
#  index_votes_on_user_id                         (user_id)
#  index_votes_on_user_id_and_winning_project_id  (user_id,winning_project_id) UNIQUE
#  index_votes_on_vote_number                     (vote_number) UNIQUE
#  index_votes_on_winning_project_id              (winning_project_id)
#
# Foreign Keys
#
#  fk_rails_...  (loser_id => projects.id)
#  fk_rails_...  (marked_invalid_by_id => users.id)
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (winning_project_id => projects.id)
#
class Vote < ApplicationRecord
  belongs_to :user
  belongs_to :winning_project, class_name: "Project", optional: true
  belongs_to :marked_invalid_by, class_name: "User", optional: true

  has_many :vote_changes, dependent: :destroy

  validates :explanation, presence: true, length: { minimum: 10 }
  validates :status, inclusion: { in: %w[active invalid] }
  validates :vote_number, presence: true, uniqueness: true

  # only for ties
  validates :winning_project_id, presence: true, unless: :tie?

  attr_accessor :token, :project_1_id, :project_2_id

  after_create :potentially_pay_out_yayyyyy

  scope :active, -> { where(status: "active") }
  scope :invalid, -> { where(status: "invalid") }
  scope :recent, -> { order(created_at: :desc) }

  before_validation :set_vote_number, on: :create
  after_create :process_vote_results

  def tie?
    winning_project_id.nil?
  end

  def winner
    winning_project
  end

  def loser
    return nil if tie?
    vote_changes.joins(:project).find { |vc| vc.project_id != winning_project_id }&.project
  end

  def projects
    vote_changes.includes(:project).map(&:project)
  end

  def authorized_with_token?(token_data)
    return false unless token_data

    token_data["user_id"] == user_id &&
      token_data["project_1_id"] == project_1_id &&
      token_data["project_2_id"] == project_2_id &&
      Time.zone.parse(token_data["expires_at"]) > Time.current
  end

  private

  def potentially_pay_out_yayyyyy
    # if loser.votes.count == Payout::VOTE_COUNT_REQUIRED

    # end
  end

  def unlerp(start, stop, value)
    return 0.0 if start == stop
    (value - start) / (stop - start).to_f
  end

  def mark_invalid!(reason, marked_by_user)
    update!(
      status: "invalid",
      invalid_reason: reason,
      marked_invalid_at: Time.current,
      marked_invalid_by: marked_by_user
    )
  end

  def set_vote_number
    self.vote_number = (Vote.maximum(:vote_number) || 0) + 1
  end

  def process_vote_results
    VoteProcessingService.new(self).process
  end
end
