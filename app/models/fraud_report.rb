# == Schema Information
#
# Table name: fraud_reports
#
#  id           :bigint           not null, primary key
#  reason       :string
#  suspect_type :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  suspect_id   :bigint
#  user_id      :bigint           not null
#
# Indexes
#
#  index_fraud_reports_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class FraudReport < ApplicationRecord
  belongs_to :suspect, polymorphic: true
  belongs_to :reporter, class_name: "User", foreign_key: "user_id"
end
