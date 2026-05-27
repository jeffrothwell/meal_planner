require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET / returns 200" do
    get root_path
    assert_response :success
  end
end
