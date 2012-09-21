require 'test_helper'

class SanSemestersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:san_semesters)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create san_semester" do
    assert_difference('SanSemester.count') do
      post :create, :san_semester => { }
    end

    assert_redirected_to san_semester_path(assigns(:san_semester))
  end

  test "should show san_semester" do
    get :show, :id => san_semesters(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => san_semesters(:one).to_param
    assert_response :success
  end

  test "should update san_semester" do
    put :update, :id => san_semesters(:one).to_param, :san_semester => { }
    assert_redirected_to san_semester_path(assigns(:san_semester))
  end

  test "should destroy san_semester" do
    assert_difference('SanSemester.count', -1) do
      delete :destroy, :id => san_semesters(:one).to_param
    end

    assert_redirected_to san_semesters_path
  end
end
