require "test_helper"

class SignpostControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get signpost_index_url
    assert_response :success
  end

  test "should get show" do
    get signpost_show_url
    assert_response :success
  end
end
