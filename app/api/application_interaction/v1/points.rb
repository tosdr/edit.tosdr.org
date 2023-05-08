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
          current_user_authenticated = current_user && (current_user.admin || current_user.curator)
          error!('404 Not found', 404) unless annotation_id.present? && current_user_authenticated
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
          service = Service.find(params[:service_id]&.to_i)
          document = Document.find(params[:document_id]&.to_i)
          case_title = params[:case_title]&.strip
          case_ref = Case.find_by_title(case_title)
          point = Point.find_by_annotation_ref(params[:annotation_id])
          if point.update!(service: service, case: case_ref, user: point.user, analysis: point.analysis, title: case_ref.title, status: point.status, annotation_ref: point.annotation_ref, document: document)
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
