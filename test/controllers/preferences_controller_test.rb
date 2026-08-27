require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get preferences_edit_url
    assert_response :success
  end
end
