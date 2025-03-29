class Family < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :orders, dependent: :nullify
  has_and_belongs_to_many :whatsapp_messages


  before_create :generate_token

  def confirmed_members_count
    members.where(confirmed: true).count
  end

  def total_members_count
    members.count
  end

  def confirmation_rate
    total = total_members_count
    return 0 if total == 0
    (confirmed_members_count.to_f / total * 100).round(1)
  end

  def confirmation_status
    rate = confirmation_rate
    if rate == 0
      :none
    elsif rate < 100
      :partial
    else
      :complete
    end
  end

  private

  def generate_token
    # Exemplo: "PG-ABC123"
    self.token ||= "PG-#{SecureRandom.alphanumeric(6).upcase}"
  end
end
