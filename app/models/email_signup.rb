# == Schema Information
#
# Table name: email_signups
#
#  id         :bigint           not null, primary key
#  email      :text             not null
#  ip         :inet
#  ref        :string
#  synced_at  :datetime
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_email_signups_on_email  (email) UNIQUE
#
class EmailSignup < ApplicationRecord
end
