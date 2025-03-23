class WhatsappMessage < ApplicationRecord
  # Relação many-to-many: uma mensagem pode ser enviada para várias famílias.
  has_and_belongs_to_many :families

  # Upload de imagem via ActiveStorage
  has_one_attached :image

  validates :content, presence: true
  validates :families, presence: true

  # Status global da mensagem (batch)
  # Como o enum nativo não funcionou para você, definiremos manualmente:
  STATUS_PENDING  = "pending"
  STATUS_SENDING  = "sending"
  STATUS_SENT     = "sent"
  STATUS_FAILED   = "failed"
  STATUS_PARTIAL  = "partial"

  # O status é armazenado na coluna "status" (por exemplo, string)
  # Os getters e setters abaixo permitem usar valores como "pending", etc.
  def status
    read_attribute(:status) || STATUS_PENDING
  end

  def status=(new_status)
    new_status = new_status.to_s
    case new_status
    when STATUS_PENDING, STATUS_SENDING, STATUS_SENT, STATUS_FAILED, STATUS_PARTIAL
      write_attribute(:status, new_status)
    else
      raise ArgumentError, "Invalid status: #{new_status}"
    end
  end

  # Para facilitar a exibição do progresso
  def progress
    "#{sent_count}/#{total_count}"
  end
end
