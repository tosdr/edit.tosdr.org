# frozen_string_literal: true

module ApplicationInteraction
  module V1
    # api facility for interacting with hypothesis annotator
    class Points < Grape::API
      version 'v1'
      format :json
      prefix :api

      helpers do
        def current_user
          # authenticate using the h_key cookie and the client-side authenticated user's username
          if params[:h_key]
            user = User.find_by_h_key(params[:h_key])
            return user unless !user || user.username != params[:user]
          end
        end

        def authenticate!
          annotation_id = params[:annotation_id] || ''
          document_id = params[:document_id] || ''
          service_id = params[:service_id] || ''
          case_title = params[:case_title] || ''
          required_params_present = case_title.present? && annotation_id.present? && document_id.present? && service_id.present?
          error!('404 Not found', 404) unless required_params_present && current_user
        end
      end

      resource :points do
        desc 'Links point to annotation'

        post do
          params do
            require :annotation_id, type: String
            require :case_title, type: String
            require :service_id, type: String
            require :document_id, type: String
            require :user, type: String
          end

          authenticate!
          service = Service.find(params[:service_id]&.to_i)
          document = Document.find(params[:document_id]&.to_i)
          case_title = params[:case_title]&.strip
          case_ref = Case.find_by_title(case_title)
          point = Point.new(service: service, case: case_ref, user: current_user, analysis: 'Generated through the annotate view', title: case_ref.title, status: 'pending', annotation_ref: params[:annotation_id], document: document)
          if point.save
            present point, with: ::ApplicationInteraction::Entities::Point
          else
            error!('404 Not found', 404)
          end
        end

        patch do
          params do
            require :annotation_id, type: String
            require :case_title, type: String
            require :service_id, type: String
            require :document_id, type: String
            require :user, type: String
          end

          authenticate!
          case_title = params[:case_title]&.strip
          case_ref = Case.find_by_title(case_title)
          point = Point.find_by_annotation_ref(params[:annotation_id])

          if (point.user != current_user) && !current_user.curator?
            error!('404 Not found', 404)
          end

          if point.update!(case: case_ref, title: case_ref.title)
            present point, with: ::ApplicationInteraction::Entities::Point
          else
            error!('404 Not found', 404)
          end
        end

        delete do
          params do
            require :annotation_id, type: String
          end

          authenticate!
          point = Point.find_by_annotation_ref(params[:annotation_id])
          point.destroy!
        end
      end
    end
  end
end
