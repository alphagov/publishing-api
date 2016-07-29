class DownstreamDraftWorker
  attr_reader :content_item_id, :payload_version, :update_dependencies

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise CommandError.new(
        code: 404,
        message: "The content item for id: #{content_item_id} was not found",
      )
    end

    unless content_item_state?(:draft, :published)
      raise CommandError.new(
        code: 500,
        message: "Can only downstream draft a draft or published content item",
      )
    end

    send_to_draft_content_store if should_send_to_content_store?
    enqueue_dependencies if update_dependencies
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def send_to_draft_content_store
    payload = presented_content_store_payload
    base_path = payload.fetch(:base_path)
    draft_content_store.put_content_item(base_path, payload)
  end

  def should_send_to_content_store?
    web_content_item.base_path != nil
  end

  def draft_content_store
    Adapters::DraftContentStore
  end

  def web_content_item
    @web_content_item ||= Queries::GetWebContentItems.(content_item_id).first
  end

  def content_item_state?(*allowed_states)
    states = allowed_states.map(&:to_s)
    current_state = State.where(content_item_id: content_item_id).pluck(:name).first
    states.include?(current_state)
  end

  def presented_content_store_payload
    Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: draft_content_store::DEPENDENCY_FALLBACK_ORDER
    )
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: draft_content_store,
      fields: presented_content_store_payload.keys,
      content_id: web_content_item.content_id,
      payload_version: payload_version
    )
  end
end
