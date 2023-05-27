# frozen_string_literal: true

module ApplicationInteraction
  module V1
    # api facility for interacting with hypothesis annotator
    class Cases < Grape::API
      version 'v1'
      format :json
      prefix :api
      helpers do
        def current_user
          # authenticate using the h_key cookie and the client-side authenticated user's username
          if request.headers['H-Key']
            user = User.find_by_h_key(request.headers['H-Key'])
            return user unless !user || user.username != request.headers['User']
          end
        end

        def authenticate!
          error!('404 Not found', 404) unless current_user
        end
      end

      resource :cases do
        desc 'Retrieves cases'

        get do
          authenticate!
          cases = Case.all
          present cases, with: ::ApplicationInteraction::Entities::Case
        end
      end
    end
  end
end