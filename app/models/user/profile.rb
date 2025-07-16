# == Schema Information
#
# Table name: user_profiles
#
#  id         :bigint           not null, primary key
#  bio        :text
#  custom_css :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_user_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class User::Profile < ApplicationRecord
  belongs_to :user

  validates :bio, length: { maximum: 1000 }, allow_blank: true
  validates :custom_css, length: { maximum: 10_000 }, allow_blank: true
  validate :custom_css_requires_badge
  validate :fucking_xss

  private

  def custom_css_requires_badge
    return if custom_css.blank?

    unless user.has_badge?(:graphic_design_is_my_passion)
      errors.add(:custom_css, "requires the 'Graphic Design is My Passion' badge")
    end
  end

  def fucking_xss
    return if custom_css.blank?

    if custom_css.include?("</style>")
      errors.add(:base, "nice try jackwagon")
    end
  end
end
