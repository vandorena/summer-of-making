# == Schema Information
#
# Table name: email_signups
#
#  id         :bigint           not null, primary key
#  email      :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class EmailSignup < ApplicationRecord
end
