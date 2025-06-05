# == Schema Information
#
# Table name: magic_links
#
#  id         :bigint           not null, primary key
#  token      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_magic_links_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class MagicLink < ApplicationRecord
  belongs_to :user

  VALIDITY_PERIOD = 1.day

  def expires_at
    created_at + 1.day
  end
end
