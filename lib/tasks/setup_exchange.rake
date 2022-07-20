desc "Create RabbitMQ exchanges"
task setup_exchange: :environment do
  config = Rails.application.config_for(:rabbitmq)

  bunny = Bunny.new(ENV["RABBITMQ_URL"])
  channel = bunny.start.create_channel
  Bunny::Exchange.new(channel, :topic, config[:exchange])
end
