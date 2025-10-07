module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_with_api_key!
    attr_reader :current_client
  end

  private

  def authenticate_with_api_key!
    api_key = extract_api_key

    unless api_key
      render_unauthorized("API key is missing")
      return
    end

    @current_client = Client.active.find_by(api_key: api_key)

    unless @current_client
      render_unauthorized("Invalid or inactive API key")
    end
  end

  def extract_api_key
    # Check Authorization header first (Bearer token)
    if request.headers["Authorization"].present?
      request.headers["Authorization"].to_s.remove("Bearer ").strip
    # Then check X-API-Key header
    elsif request.headers["X-API-Key"].present?
      request.headers["X-API-Key"]
    # Finally check query parameter (least secure, use only for testing)
    elsif params[:api_key].present?
      params[:api_key]
    end
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end
end
