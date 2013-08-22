require 'test_helper'

class SanSubjectsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:san_subjects)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create san_subject" do
    assert_difference('SanSubject.count') do
      post :create, :san_subject => { }
    end

    assert_redirected_to san_subject_path(assigns(:san_subject))
  end

  test "should show san_subject" do
    get :show, :id => san_subjects(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => san_subjects(:one).to_param
    assert_response :success
  end

  test "should update san_subject" do
    put :update, :id => san_subjects(:one).to_param, :san_subject => { }
    assert_redirected_to san_subject_path(assigns(:san_subject))
  end

  test "should destroy san_subject" do
    assert_difference('SanSubject.count', -1) do
      delete :destroy, :id => san_subjects(:one).to_param
    end

    assert_redirected_to san_subjects_path
  end
end
