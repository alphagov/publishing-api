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

  desc "Add live editions to the message queue by document type"
  task :requeue_document_type, [] => :environment do |_, args|
    document_types = args.extras
    raise "expecting document_type" if document_types.blank?

    RequeueContentByScope.new(
      Edition.live.where(document_type: document_types),
    ).call
  end

  desc "Add all live editions to the message queue with a specified routing key"
  # This is similar to `represent_downstream:all` except it does not
  # affect the live and draft content stores, and the routing key can
  # be customised to target a particular app that feeds off the
  # message queue. For example, use the following command to send data
  # to the Content Data API:
  #
  #   rake queue:requeue_all_the_things[bulk.data-warehouse]
  #
  task :requeue_all_the_things, [:action] => :environment do |_, args|
    RequeueContentByScope.new(Edition.live, action: args.action).call
  end

  # This is similar to requeue_all_the_things, but it enqueues the most relevant edition for all
  # content that has at one point been published.
  #
  # This is suitable for downstream apps that need to know about all content past and present,
  # not just that which is currently visible to users, for example to be able to delete content
  # downstream that has been unpublished upstream.
  desc "Add all published and unpublished editions to the message queue with a specified routing key"
  task :requeue_all_the_ever_published_things, [:action] => :environment do |_, args|
    RequeueContentByScope.new(
      Edition.where(state: %w[published unpublished]),
      action: args.action,
    ).call
  end

  # This is similar to requeue_all_the_things, but it only requeues published documents
  #
  # This is suitable for e.g. initial import of data into a new downstream app that doesn't care
  # about content that is no longer visible to users.
  desc "Requeue all published editions with a specific routing key"
  task :requeue_all_the_published_things, [:action] => :environment do |_, args|
    RequeueContentByScope.new(
      Edition.live.where(state: "published"),
      action: args.action,
    ).call
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
