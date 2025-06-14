module HighSeasReviewsHelper
  def get_review_image_path(image_path)
    return nil if image_path.blank?
    if image_path.start_with?("/temp/hsr/")
      image_path
    elsif image_path.start_with?("http")
      "clubhuman.png"
    else
      image_path
    end
  end
end
