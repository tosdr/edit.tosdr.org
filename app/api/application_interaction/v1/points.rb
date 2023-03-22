# frozen_string_literal: true

module ApplicationInteraction
  module V1
    # api facility for interacting with hypothesis annotator
    class Points < Grape::API
      version 'v1'
      format :json
      prefix :api

      helpers do
        def warden
          env['warden']
        end

        def authenticated
          warden&.authenticated?
        end

        def current_user
          # hack - warden user object isn't available when call to api is made from outside phoenix
          warden.user || User.find_by_username(params[:user])
        end

        def authenticate!
          api_key = params[:h_api_key] || ''
          annotation_id = params[:annotation_id] || ''
          current_user_authenticated = current_user && (current_user.admin || current_user.curator)
          error!('404 Not found', 404) unless annotation_id.present? && api_key.present? && ENV['H_API_KEY'] == api_key && current_user_authenticated
        end
      end

      resource :points do
        desc 'Links point to annotation'

        post do
          params do
            require :h_api_key, type: String
            require :annotation_id, type: String
            require :case_title, type: String
            require :service_id, type: String
            require :user, type: String
          end

          authenticate!
          service = Service.find(params[:service_id]&.to_i)
          case_ref = Case.find_by_title(params[:case_title])
          point = Point.new(service: service, case: case_ref, user: current_user, analysis: 'Generated through the annotate view', title: case_ref.title, status: 'pending', annotation_ref: params[:annotation_id])
          if point.save
            present point, with: ::ApplicationInteraction::Entities::Point
          else
            error!('404 Not found', 404)
          end
        end
      end
    end
  end
end
