environment ENV.fetch("RAILS_ENV") { "production" }


threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

port ENV.fetch("PORT", 3000)

# Configuração de workers para produção
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Pré-carrega a aplicação para otimizar o uso de memória entre os workers
preload_app!

# Reestabelece conexões com o banco de dados em cada worker
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

plugin :tmp_restart

pidfile ENV["PIDFILE"] if ENV["PIDFILE"]
