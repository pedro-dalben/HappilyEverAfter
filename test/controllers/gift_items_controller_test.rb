require "test_helper"

class GiftItemsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get gift_items_index_url
    assert_response :success
  end

  test "should get show" do
    get gift_items_show_url
    assert_response :success
  end

  test "should get new" do
    get gift_items_new_url
    assert_response :success
  end

  test "should get edit" do
    get gift_items_edit_url
    assert_response :success
  end
end
