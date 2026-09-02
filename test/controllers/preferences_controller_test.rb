require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "cuisines@example.com",
      password: "password",
      average_lunch_time_minutes: 30,
      max_walking_minutes: 10
    )
    sign_in @user
  end

  test "should get edit" do
    get edit_preferences_url
    assert_response :success
  end

  test "update_cuisines redirects to locations when session has no location" do
    patch cuisines_preferences_url, params: { user: { tag_ids: [] } }

    assert_redirected_to locations_path
    assert_equal "Nous avons besoin de votre position.", flash[:alert]
  end
end
