MAX_IMPORT_QUEUE_SIZE = 1000

namespace :queue do
  desc "Watch the queue, and print messages on the console"
  task watcher: :environment do
    config = Rails.application.config_for("rabbitmq").symbolize_keys

    conn = Bunny.new(config)
    conn.start

    ch = conn.create_channel
    ex = ch.topic(config[:exchange], passive: true)
    q = ch.queue("", exclusive: true)
    q.bind(ex, routing_key: "#")

    at_exit do
      puts "Closing channel"
      ch.close
      conn.close
    end

    puts "Listening for messages"
    q.subscribe(block: true) do |delivery_info, properties, payload|
      puts <<-MESSAGE.strip_heredoc
        ----- New Message -----
        Routing_key: #{delivery_info.routing_key}
        Properties: #{properties.inspect}
        Payload: #{payload}
      MESSAGE
    end
  end

  desc "Add published editions to the message queue by document type"
  task :requeue_document_type, [] => :environment do |_, args|
    document_types = args.extras

    raise(StandardError, "expecting document_type") if document_types.blank?

    version = Event.maximum(:id)

    # Restrict scope to stuff that's live (published or withdrawn)
    scope = Edition
      .with_document
      .where(document_type: document_types)
      .where(content_store: :live)
      .select(:id)

    scope.find_each do |edition|
      RequeueContent.perform_async(edition.id, version)
    end
  end

  desc "Add all published editions to the message queue with a specified routing key"
  # This is similar to `represent_downstream:all` except it does not
  # affect the live and draft content stores, and the routing key can
  # be customised to target a particular app that feeds off the
  # message queue. For example, use the following command to send data
  # to the Content Data API:
  #
  #   rake queue:requeue_all_the_things[bulk.data-warehouse]
  #
  task :requeue_all_the_things, [:action] => :environment do |_, args|
    action = args.action

    raise(StandardError, "expecting action") if action.blank?

    if /major/.match?(action)
      raise(StandardError, "resending major updates is a bad idea: it will spam everyone with email alerts")
    end

    version = Event.maximum(:id)

    # Restrict scope to stuff that's live (published or withdrawn)
    scope = Edition
      .with_document
      .where(content_store: :live)
      .select(:id)

    queue = Sidekiq::Queue.new("import")

    scope.find_each.with_index do |edition, i|
      warn "Queueing edition #{i}"

      # We don't want to swamp the queue with messages if the consumer isn't
      # keeping up. So if the queue gets over a certain size, pause this job.
      while queue.size > MAX_IMPORT_QUEUE_SIZE
        warn "Queue size has exceeded #{MAX_IMPORT_QUEUE_SIZE}, waiting for messages to be processed before continuing."
        sleep 5
      end

      RequeueContent.perform_async(edition.id, version, action)
    end
  end

  desc "Preview of the message published onto rabbit MQ"
  task :preview_recent_message, [:document_type] => :environment do |_, args|
    document_type = args[:document_type]
    raise(StandardError, "expecting document_type") if document_type.blank?

    edition = Edition
              .with_document
              .order(public_updated_at: :desc)
              .find_by!(
                editions: { state: "published" },
                document_type:,
              )
    version = Event.maximum(:id)

    presenter = DownstreamPayload.new(edition, version, draft: false)
    payload = presenter.message_queue_payload

    pp payload
  end
end
