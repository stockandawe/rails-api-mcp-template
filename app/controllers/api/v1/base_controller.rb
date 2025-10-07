module Api
  module V1
    class BaseController < ApplicationController
      include ApiKeyAuthenticatable

      rescue_from ArgumentError, with: :render_bad_request

      private

      def render_bad_request(exception)
        render json: { error: exception.message }, status: :bad_request
      end
    end
  end
end
