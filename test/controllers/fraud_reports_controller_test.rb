# frozen_string_literal: true

require "test_helper"

class FraudReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @project = projects(:one)
    sign_in @user
  end

  test "should create fraud report successfully" do
    assert_difference("FraudReport.count") do
      post fraud_reports_path, params: {
        fraud_report: {
          suspect_type: "Project",
          suspect_id: @project.id,
          reason: "spam"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Thank you for reporting this. We'll investigate.", flash[:notice]
  end

  test "should prevent duplicate fraud reports" do
    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    # try dupes
    assert_no_difference("FraudReport.count") do
      post fraud_reports_path, params: {
        fraud_report: {
          suspect_type: "Project",
          suspect_id: @project.id,
          reason: "fake_project"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "You have already reported this project.", flash[:alert]
  end

  test "should allow different users to report the same project" do
    other_user = users(:two)

    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    sign_in other_user

    assert_difference("FraudReport.count") do
      post fraud_reports_path, params: {
        fraud_report: {
          suspect_type: "Project",
          suspect_id: @project.id,
          reason: "fake_project"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Thank you for reporting this. We'll investigate.", flash[:notice]
  end

  test "should allow same user to report different projects" do
    other_project = projects(:two)

    FraudReport.create!(
      reporter: @user,
      suspect_type: "Project",
      suspect_id: @project.id,
      reason: "spam"
    )

    assert_difference("FraudReport.count") do
      post fraud_reports_path, params: {
        fraud_report: {
          suspect_type: "Project",
          suspect_id: other_project.id,
          reason: "fake_project"
        }
      }
    end

    assert_redirected_to root_path
    assert_equal "Thank you for reporting this. We'll investigate.", flash[:notice]
  end
end
