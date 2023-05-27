require 'rails_helper'

describe ApplicationInteraction::V1::Points, type: :request do
  before :each do
    @user = FactoryBot.create(:user_confirmed, h_key: 'testkey1234')
    @user.save!

    @case_ref = FactoryBot.create :case
    @service = FactoryBot.create :service
    @document = FactoryBot.create :document
    @annotation_id = 'test1234'
  end

  describe 'authentication' do
    it 'returns 404 if username does not match h_key' do
      post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, h_key: @user.h_key, document_id: @document.id, service_id: @service.id, user: 'wrongusername' }
      expect(response.status).to eq(404)
    end

    it 'returns 404 if h_key does not match username' do
      post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, h_key: 'wronghkey', user: @user.username, document_id: @document.id, service_id: @service.id }
      expect(response.status).to eq(404)
    end

    context 'missing params' do
      it 'returns 404 if no annotation_id in params' do
        post '/api/v1/points', params: { case_title: @case_ref.title, h_key: @user.h_key, user: @user.username, service_id: @service.id, document_id: @document.id }
        expect(response.status).to eq(404)
      end

      it 'returns 404 if no h_key in params' do
        post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, service_id: @service.id, user: @user.username, document_id: @document.id }
        expect(response.status).to eq(404)
      end

      it 'returns 404 if no h_key in params' do
        post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, service_id: @service.id, user: @user.username, document_id: @document.id }
        expect(response.status).to eq(404)
      end

      it 'returns 404 if annotation_id blank in params' do
        post '/api/v1/points', params: { annotation_id: '', case_title: @case_ref.title, h_key: @user.h_key, user: @user.username, service_id: @service.id, document_id: @document.id }
        expect(response.status).to eq(404)
      end
    end

    context 'malformed params' do
      it 'returns 201 if trailing whitespaces in case_title' do
        post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title + "    ", h_key: @user.h_key, user: @user.username, service_id: @service.id, document_id: @document.id }
        expect(response.status).to eq(201)
      end
    end
  end

  describe 'POST /api/v1/points' do
    it 'returns 404 for unauthenticated user' do
      post '/api/v1/points'
      expect(response.status).to eq(404)
    end

    it 'returns 201 if point is created successfully' do
      post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @service.id }
      expect(response.status).to eq(201)
    end
  end

  describe 'PATCH /api/v1/points' do
    before :each do
      case_ref = FactoryBot.create(:case)
      @point = FactoryBot.create(:point, annotation_ref: @annotation_id, case_id: case_ref.id)
      @point.save!
    end

    it 'returns 404 for unauthenticated user' do
      patch '/api/v1/points'
      expect(response.status).to eq(404)
    end

    # to-do : limit what we can update via the api? don't want to update the service id, document id, for example
    it 'returns 201 if point is updated successfully' do
      new_case = FactoryBot.create(:case)
      new_case.save!
      post '/api/v1/points', params: { annotation_id: @point.annotation_ref, case_title: new_case.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @point.document.service.id }
      expect(response.status).to eq(201)
    end
  end

  describe 'DELETE /api/v1/points' do
    before :each do
      case_ref = FactoryBot.create(:case)
      @point = FactoryBot.create(:point, annotation_ref: @annotation_id, case_id: case_ref.id)
      @point.save!
    end

    it 'returns 404 for unauthenticated user' do
      delete '/api/v1/points'
      expect(response.status).to eq(404)
    end

    # to-do : limit what we can update via the api? don't want to update the service id, document id, for example
    it 'returns 201 if point is updated successfully' do
      delete '/api/v1/points', params: { annotation_id: @point.annotation_ref, case_title: @point.case.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @point.document.service.id }
      expect(response.status).to eq(200)
    end
  end
end
