class PresentedContentStoreWorker
  attr_reader :params, :request_uuid
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(args = {})
    assing_attributes(args.deep_symbolize_keys)
    set_headers

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
      base_path = presented_payload.fetch(:base_path)
      content_store.put_content_item(base_path, presented_payload)
    else
      base_path = payload.fetch(:base_path)
      content_store.put_content_item(base_path, payload)
    end
  end

  def presented_payload
    Presenters::ContentStorePresenter.present(content_item, payload_version, state_fallback_order: content_store::DEPENDENCY_FALLBACK_ORDER)
  end

  def payload_version
    payload.fetch(:payload_version)
  end

  def delete_from_content_store
    base_path = params.fetch(:base_path)
    content_store.delete_content_item(base_path)
  end

  def set_headers
    logger.debug "[#{request_uuid}] PresentedContentStoreWorker#perform with #{params}"
    GdsApi::GovukHeaders.set_header(:govuk_request_id, request_uuid)
  end

  def content_store
    params.fetch(:content_store).constantize
  end

  def assing_attributes(params)
    @params = params
    @request_uuid = @params[:request_uuid]
  end

  def payload
    params.fetch(:payload, {})
  end

  def content_item_id
    payload[:content_item_id]
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
      request_uuid: request_uuid,
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
