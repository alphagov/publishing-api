class ContentStoreWorker
  include Sidekiq::Worker

  sidekiq_options queue: :content_store

  def perform(args = {})
    args = args.deep_symbolize_keys

    logger.debug "[#{args[:request_uuid]}] ContentStoreWorker#perform with #{args}"

    content_store = args.fetch(:content_store).constantize

    if args[:delete]
      content_store.delete_content_item(args.fetch(:base_path))
    else
      content_item = load_content_item_from(args)
      raise_no_content_item(args) unless content_item
      payload = Presenters::ContentStorePresenter.present(
        content_item,
        mock_event(content_item)
      )
      ensure_access_limited_is_not_sent_to_live(payload, content_store)
      content_store.put_content_item(payload.fetch(:base_path), payload)
    end

  rescue => e
    handle_error(e)
  end

  def self.perform_with_defaults(opts)
    keys = [:content_store, :content_item_id, :base_path, :delete]
    opts = opts.select { |k,v| keys.include?(k) }

    opts[:content_store] = opts[:content_store] || Adapters::DraftContentStore
    opts[:request_uuid] = GdsApi::GovukHeaders.headers[:x_govuk_request_uuid]

    perform_in(2.seconds, opts)
  end

private

  # Previously, the content_store_payload_id was sourced from a separate table.
  #
  # We need to choose an id that is higher than the existing versions in content
  # store. The content item's id should always be higher than these numbers.
  #
  # We also need to choose an id that will be lower than any subsequent payload
  # versions taken from event ids.
  #
  # This will allow those messages to be cleared out from the queue.
  def mock_event(content_item)
    OpenStruct.new(id: content_item.id)
  end

  def load_content_item_from(args)
    ContentItem.find_by(id: args.fetch(:content_item_id))
  end

  def raise_no_content_item(args)
    id = args.fetch(:content_item_id)
    content_store = args.fetch(:content_store)
    name = content_store == "Adapters::ContentStore" ? "Live" : "Draft"

    message = "Tried to send ContentItem with id=#{id} to the #{name} Content Store"
    message += " but it no longer exists in Publishing API's database"

    raise ActiveRecord::RecordNotFound, message
  end

  def ensure_access_limited_is_not_sent_to_live(payload, content_store)
    if content_store == Adapters::ContentStore && payload.has_key?(:access_limited)
      payload.delete(:access_limited)

      message = "Attempted to send access limited to the live content store"
      message += " for content id #{payload.fetch(:content_id)}"
      error = ConsistencyError.new(message)

      Airbrake.notify_or_ignore(error)
    end
  end

  def handle_error(error)
    if !error.is_a?(CommandError)
      raise error
    elsif error.code >= 500
      raise error
    else
      explanation = "The message is a duplicate and does not need to be retried"
      Airbrake.notify_or_ignore(error, parameters: { explanation: explanation })
    end
  end

  class ::ConsistencyError < StandardError; end
end
