require 'rails_helper'

describe ApplicationInteraction::V1::Points, type: :request do
  before :each do
    @user = FactoryBot.create(:user_confirmed, h_key: 'testkey1234')
    @user.save!

    @case_ref = FactoryBot.create :case
    @service = FactoryBot.create :service
    @document = FactoryBot.create :document
    @annotation_id = 'QKfL6h_tEe6a1cM4U_gFDw'

    host! 'example.com'
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
        allow(Point).to receive(:retrieve_annotation).and_return(
          'target_selectors' => [{}, {}, { 'exact' => 'Example policy text' }].to_json
        )

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

    it 'returns 404 for an unknown case_title' do
      post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: 'missing case', h_key: @user.h_key, user: @user.username, service_id: @service.id, document_id: @document.id }
      expect(response.status).to eq(404)
    end

    it 'returns 201 if point is created successfully' do
      # TO-DO: create annotation table 
      # post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: @case_ref.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @service.id }
      # expect(response.status).to eq(201)
    end
  end

  # Some stored case titles carry leading/trailing whitespace. Trimming only the incoming
  # title made those cases unmatchable by any payload: sending the title verbatim failed
  # (the space was stripped off the request) and sending it trimmed failed too (the stored
  # value still had it), so every point on those cases 404'd.
  describe 'case titles with surrounding whitespace in the database' do
    before :each do
      allow(Point).to receive(:retrieve_annotation).and_return(
        'target_selectors' => [{}, {}, { 'exact' => 'Example policy text' }].to_json
      )

      # update_columns so the row genuinely carries the padding, whatever the factory does
      @padded_case = FactoryBot.create(:case)
      @padded_case.update_columns(title: ' Tracks you across the web ')
    end

    def post_point(case_title)
      post '/api/v1/points', params: { annotation_id: @annotation_id, case_title: case_title,
                                       h_key: @user.h_key, user: @user.username,
                                       service_id: @service.id, document_id: @document.id }
    end

    it 'creates a point when the caller sends the padded title verbatim' do
      post_point(' Tracks you across the web ')

      expect(response.status).to eq(201)
      expect(Point.last.case).to eq(@padded_case)
    end

    it 'creates a point when the caller sends the padded title trimmed' do
      post_point('Tracks you across the web')

      expect(response.status).to eq(201)
      expect(Point.last.case).to eq(@padded_case)
    end

    it 'still returns 404 when no case matches even after trimming' do
      post_point('   not a real case   ')

      expect(response.status).to eq(404)
    end

    it 'updates a point onto a case whose stored title is padded' do
      point = FactoryBot.create(:point, annotation_ref: @annotation_id, case_id: @case_ref.id,
                                        user: @user, status: 'pending')

      patch '/api/v1/points', params: { annotation_id: @annotation_id,
                                        case_title: 'Tracks you across the web',
                                        h_key: @user.h_key, user: @user.username,
                                        service_id: @service.id, document_id: @document.id }

      expect(response.status).to eq(200)
      expect(point.reload.case).to eq(@padded_case)
    end
  end

  describe 'PATCH /api/v1/points' do
    before :each do
      case_ref = FactoryBot.create(:case)
      @point = FactoryBot.create(:point, annotation_ref: @annotation_id, case_id: case_ref.id, user: @user, status: 'pending')
      @point.save!
    end

    it 'returns 404 for unauthenticated user' do
      patch '/api/v1/points'
      expect(response.status).to eq(404)
    end

    it 'returns 404 for an authenticated unknown annotation_id' do
      patch '/api/v1/points', params: { annotation_id: 'missing', case_title: @point.case.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @point.document.service.id }
      expect(response.status).to eq(404)
    end

    it 'returns 201 if point is updated successfully' do
      # TO-DO: create annotation table 
      # new_case = FactoryBot.create(:case)
      # new_case.save!
      # post '/api/v1/points', params: { annotation_id: @point.annotation_ref, case_title: new_case.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @point.document.service.id }
      # expect(response.status).to eq(201)
    end
  end

  describe 'DELETE /api/v1/points' do
    before :each do
      case_ref = FactoryBot.create(:case)
      @point = FactoryBot.create(:point, annotation_ref: @annotation_id, case_id: case_ref.id, user: @user, status: 'pending')
      @point.save!
    end

    it 'returns 404 for unauthenticated user' do
      delete '/api/v1/points'
      expect(response.status).to eq(404)
    end

    it 'returns 404 for an authenticated unknown annotation_id' do
      delete '/api/v1/points', params: { annotation_id: 'missing', h_key: @user.h_key, user: @user.username }
      expect(response.status).to eq(404)
    end

    it 'returns 404 and does not decline a point for a non-owner non-curator' do
      other_user = FactoryBot.create(:user_confirmed, h_key: 'otherkey1234', admin: false, curator: false)

      delete '/api/v1/points', params: { annotation_id: @point.annotation_ref, h_key: other_user.h_key, user: other_user.username }

      expect(response.status).to eq(404)
      expect(@point.reload.status).not_to eq('declined')
    end

    it 'allows a curator to decline another user point' do
      curator = FactoryBot.create(:user_confirmed, h_key: 'curatorkey1234', admin: false, curator: true)

      delete '/api/v1/points', params: { annotation_id: @point.annotation_ref, h_key: curator.h_key, user: curator.username }

      expect(response.status).to eq(200)
      expect(@point.reload.status).to eq('declined')
    end

    # to-do : limit what we can update via the api? don't want to update the service id, document id, for example
    it 'returns 201 if point is updated successfully' do
      delete '/api/v1/points', params: { annotation_id: @point.annotation_ref, case_title: @point.case.title, h_key: @user.h_key, user: @user.username, document_id: @document.id, service_id: @point.document.service.id }
      expect(response.status).to eq(200)
    end
  end
end
