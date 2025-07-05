module Admin
  class VotingDashboardController < ApplicationController
    def index
      @total = Vote.count
      @pool = Project.count

      counts = Vote.group(:project_1_id).count.merge(Vote.group(:project_2_id).count) { |_, a, b| a + b }
      vote_counts = counts.values

      @v10 = vote_counts.count { |c| c >= 10 }
      @v18 = vote_counts.count { |c| c >= 18 }
      @v24 = vote_counts.count { |c| c >= 24 }
      @v30 = vote_counts.count { |c| c >= 30 }
      @v50 = vote_counts.count { |c| c >= 50 }

      @top10 = Project.order(rating: :desc).limit(10)
      @bottom10 = Project.order(rating: :asc).limit(10)
      # lmao ratio pile
    end
  end
end
