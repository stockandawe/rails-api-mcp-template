class Client < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true, uniqueness: true
  validates :api_key, presence: true, uniqueness: true
  validates :active, inclusion: { in: [ true, false ] }
  validates :rate_limit, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Callbacks
  before_validation :generate_api_key, on: :create

  # Scopes
  scope :active, -> { where(active: true) }

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(32)
  end
end
