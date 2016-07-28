class DownstreamUnpublishWorker
  attr_reader :content_item_id, :payload_version, :update_dependencies
  include Sidekiq::Worker
  include PerformAsyncInQueue

  HIGH_QUEUE = "downstream_high".freeze
  LOW_QUEUE = "downstream_low".freeze

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise CommandError.new(
        code: 404,
        message: "The content item for id: #{content_item_id} was not found",
      )
    end

    unless content_item_state?(:unpublished)
      raise CommandError.new(
        code: 409,
        message: "Will not downstream unpublish a content item that isn't unpublished",
      )
    end

    update_content_store if should_send_to_content_store?
    enqueue_dependencies if update_dependencies
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def update_content_store
    case unpublishing.type
    when "withdrawal"
      payload = presented_content_store_payload
      live_content_store.put_content_item(web_content_item.base_path, payload)
    when "redirect"
      payload = presented_redirect_payload
      live_content_store.put_content_item(web_content_item.base_path, payload)
    when "gone"
      payload = presented_gone_payload
      live_content_store.put_content_item(web_content_item.base_path, payload)
    when "vanish"
      live_content_store.delete_content_item(web_content_item.base_path)
    else
      raise CommandError.new(
        code: 500,
        message: "Unexpected unpublishing type of '#{unpublishing.type}",
      )
    end
  end

  def presented_content_store_payload
    Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: live_content_store::DEPENDENCY_FALLBACK_ORDER
    )
  end

  def presented_redirect_payload
    payload = RedirectPresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      destination: unpublishing.alternative_path,
      public_updated_at: unpublishing.created_at,
    )
    payload.merge(payload_version: payload_version)
  end

  def presented_gone_payload
    payload = GonePresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      alternative_path: unpublishing.alternative_path,
      explanation: unpublishing.explanation,
    )
    payload.merge(payload_version: payload_version)
  end

  def live_content_store
    Adapters::ContentStore
  end

  def should_send_to_content_store?
    web_content_item.base_path != nil
  end

  def web_content_item
    @web_content_item ||= Queries::GetWebContentItems.(content_item_id).first
  end

  def unpublishing
    @unpublishing ||= Unpublishing.find_by!(content_item_id: content_item_id)
  end

  def content_item_state?(allowed_state)
    State.where(content_item_id: content_item_id).pluck(:name) == [allowed_state.to_s]
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: live_content_store,
      # @TODO find out if this is acceptable
      fields: [:content_id],
      content_id: web_content_item.content_id,
      payload_version: payload_version,
    )
  end
end
