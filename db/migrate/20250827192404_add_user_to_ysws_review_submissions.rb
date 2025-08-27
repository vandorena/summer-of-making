class AddUserToYswsReviewSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :ysws_review_submissions, :user, null: false, foreign_key: true
  end
end
