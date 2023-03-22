require 'rails_helper'

describe ApplicationInteraction::V1::Points, type: :request do
  def sign_in_as_user
    @user ||= FactoryBot.create :user_confirmed
    @user.save!
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    params = { 'user': { 'email' => @user.email, 'password' => @user.password } }
    post user_session_path, params: params.to_json, headers: headers
  end

  describe 'POST /api/v1/points' do
    it 'returns 404 for unauthenticated user' do
      post '/api/v1/points'
      expect(response.status).to eq(404)
    end

    it 'returns 201 if point is created successfully' do
      sign_in_as_user
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: { annotation_id: 'test1234', case_title: case_ref.title, h_api_key: ENV['H_API_KEY'], service_id: service.id }
      expect(response.status).to eq(201)
    end

    it 'returns 201 if username is passed (instead of user session)' do
      user ||= FactoryBot.create :user_confirmed
      user.save!
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: { annotation_id: 'test1234', case_title: case_ref.title, h_api_key: ENV['H_API_KEY'], service_id: service.id, user: user.username }
      expect(response.status).to eq(201)
    end

    it 'returns 404 if user is not curator, nor admin' do
      sign_in_as_user
      @user.curator = false
      @user.admin = false
      @user.save!
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: { annotation_id: 'test1234', case_title: case_ref.title, h_api_key: ENV['H_API_KEY'], service_id: service.id }
      expect(response.status).to eq(404)
    end

    it 'returns 404 if no annotation_id in params' do
      sign_in_as_user
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: { case_title: case_ref.title, h_api_key: ENV['H_API_KEY'], service_id: service.id }
      expect(response.status).to eq(404)
    end

    it 'returns 404 if no h_api_key in params' do
      sign_in_as_user
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: {  annotation_id: 'test1234', case_title: case_ref.title, service_id: service.id }
      expect(response.status).to eq(404)
    end

    it 'returns 404 if annotation_id blank in params' do
      sign_in_as_user
      case_ref = FactoryBot.create :case
      service = FactoryBot.create :service
      post '/api/v1/points', params: {annotation_id: '', case_title: case_ref.title, h_api_key: ENV['H_API_KEY'], service_id: service.id }
      expect(response.status).to eq(404)
    end
  end
end
