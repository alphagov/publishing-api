class PresentedContentStoreWorker
  attr_reader :params
  include Sidekiq::Worker
  include PerformAsyncInQueue

  HIGH_QUEUE = "content_store_high".freeze
  LOW_QUEUE = "content_store_low".freeze

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.deep_symbolize_keys)

    if params[:delete]
      delete_from_content_store
    else
      send_to_content_store
    end

    enqueue_dependencies
  rescue => e
    handle_error(e)
  end

private

  def send_to_content_store
    if content_item_id
      content_store_is_live = (content_store == Adapters::ContentStore)

      if content_store_is_live
        if State.where(content_item_id: content_item_id).pluck(:name) == ["draft"]
          raise CommandError.new(
            code: 500,
            message: "Will not send a draft content item to the live content store",
          )
        end
      end

      base_path = presented_payload.fetch(:base_path)
      content_store.put_content_item(base_path, presented_payload)
    else
      base_path = payload.fetch(:base_path)
      content_store.put_content_item(base_path, payload)
    end
  end

  def presented_payload
    web_content_item = Queries::GetWebContentItems.find(content_item.id)
    downstream_presenter = Presenters::DownstreamPresenter.new(web_content_item, nil, state_fallback_order: content_store::DEPENDENCY_FALLBACK_ORDER)
    Presenters::ContentStorePresenter.present(downstream_presenter, payload_version)
  end

  def payload_version
    payload.fetch(:payload_version)
  end

  def delete_from_content_store
    base_path = params.fetch(:base_path)
    content_store.delete_content_item(base_path)
  end

  def content_store
    params.fetch(:content_store).constantize
  end

  def assign_attributes(params)
    @params = params
  end

  def payload
    params.fetch(:payload, {})
  end

  def content_item_id
    payload[:content_item_id] || payload[:content_item]
  end

  def content_item
    ContentItem.find(content_item_id)
  end

  def enqueue_dependency_check?
    params.fetch(:enqueue_dependency_check, true)
  end

  def enqueue_dependencies
    return unless content_item_id
    return unless enqueue_dependency_check?
    DependencyResolutionWorker.perform_async(
      content_store: content_store,
      fields: presented_payload.keys,
      content_id: content_item.content_id,
      payload_version: payload_version,
    )
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
end
