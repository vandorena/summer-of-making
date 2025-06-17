# == Schema Information
#
# Table name: hackatime_projects
#
#  id         :bigint           not null, primary key
#  name       :string
#  seconds    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_hackatime_projects_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class HackatimeProject < ApplicationRecord
  belongs_to :user
end
