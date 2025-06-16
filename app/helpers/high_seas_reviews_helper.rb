module HighSeasReviewsHelper
  def get_review_image_path(submission)
    if submission.photos.attached?
      url_for(submission.photos.first)
    else
      asset_path("clubhuman.png")
    end
  end
end
