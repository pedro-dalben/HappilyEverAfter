namespace :asaas do
  desc "Configura o webhook do Asaas"
  task configure_webhook: :environment do
    webhook_url = ENV["WEBHOOK_URL"] || "https://giovanaepedro.com.br/api/webhooks/asaas"

    puts "Configurando webhook do Asaas para URL: #{webhook_url}"

    response = AsaasService.configure_webhook(webhook_url)

    if response && response["id"]
      puts "Webhook configurado com sucesso! ID: #{response["id"]}"
    else
      errors = response && response["errors"] ? response["errors"].map { |e| e["description"] }.join(", ") : "Erro desconhecido"
      puts "Erro ao configurar webhook: #{errors}"
    end
  end
end
