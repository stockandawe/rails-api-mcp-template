module Api
  module V1
    class RandomNumbersController < BaseController
      # GET /api/v1/random
      def show
        min = params[:min]&.to_i || 1
        max = params[:max]&.to_i || 100

        number = RandomNumberService.generate(min: min, max: max)

        render json: {
          number: number,
          min: min,
          max: max,
          client: @current_client.name,
          timestamp: Time.current.iso8601
        }
      end
    end
  end
end
