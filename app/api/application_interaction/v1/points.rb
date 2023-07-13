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
          h_key = params[:h_key] || request.headers['H-Key']
          username = params[:user] || request.headers['User']

          if h_key
            user = User.find_by_h_key(h_key)
            return user unless !user || user.username != username
          end
        end

        def authenticate!
          error!('404 Not found', 404) unless current_user
          set_papertrail_user(current_user&.id)
        end

        def verify_attrs!
          annotation_id = params[:annotation_id] || ''
          document_id = params[:document_id] || ''
          service_id = params[:service_id] || ''
          case_title = params[:case_title] || ''
          error!('404 Not found', 404) unless case_title.present? && annotation_id.present? && document_id.present? && service_id.present?
        end
      end

      resource :points do
        desc 'Facilitates links between points to annotations'
        
        get do
          authenticate!
          annotation_id = request.headers['Annotation-Id']
          point = Point.find_by_annotation_ref(annotation_id)
          present point, with: ::ApplicationInteraction::Entities::Point
        end

        post do
          params do
            require :annotation_id, type: String
            require :case_title, type: String
            require :service_id, type: String
            require :document_id, type: String
            require :user, type: String
          end

          authenticate!
          verify_attrs!
          service = Service.find(params[:service_id]&.to_i)
          document = Document.find(params[:document_id]&.to_i)
          case_title = params[:case_title]
          case_ref = Case.find_by_title(case_title)

          point = Point.new(service: service, case: case_ref, user: current_user, analysis: 'Generated through the annotate view', title: case_ref.title, status: 'pending', annotation_ref: params[:annotation_id], document: document)

          annotation = Point.retrieve_annotation(point.annotation_ref)
          annotation_json = JSON.parse(annotation['target_selectors'])
          point.quote_text = annotation_json[2]['exact']

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
          verify_attrs!
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
          if point.update!(status: 'declined')
            comment = PointComment.new(summary: 'This point has been marked as declined because its corresponding annotation was removed from its document.', point: point)
            comment.save
          else
            error!('404 Not found', 404)
          end
        end
      end
    end
  end
end
