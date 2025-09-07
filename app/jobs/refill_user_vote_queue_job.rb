# frozen_string_literal: true

class RefillUserVoteQueueJob < ApplicationJob
  queue_as :default
  include UniqueJob

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    queue = user.user_vote_queue || user.build_user_vote_queue.tap(&:save!)

    return unless queue.needs_refill?

    queue.refill_queue!(UserVoteQueue::QUEUE_SIZE)
  end
end
