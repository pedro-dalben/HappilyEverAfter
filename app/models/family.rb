class Family < ApplicationRecord
  has_many :members, dependent: :destroy
  has_and_belongs_to_many :whatsapp_messages


  before_create :generate_token

  private

  def generate_token
    # Exemplo: "PG-ABC123"
    self.token ||= "PG-#{SecureRandom.alphanumeric(6).upcase}"
  end
end
