# frozen_string_literal: true

# == Schema Information
#
# Table name: projects
#
#  id                     :bigint           not null, primary key
#  category               :string
#  demo_link              :string
#  description            :text
#  hackatime_project_keys :string           default([]), is an Array
#  is_deleted             :boolean          default(FALSE)
#  is_shipped             :boolean          default(FALSE)
#  rating                 :integer
#  readme_link            :string
#  repo_link              :string
#  title                  :string
#  used_ai                :boolean
#  ysws_submission        :boolean          default(FALSE), not null
#  ysws_type              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_projects_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
