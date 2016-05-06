class PresentedContentStoreWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform(args = {})
    args = args.deep_symbolize_keys

    logger.debug "[#{args[:request_uuid]}] PresentedContentStoreWorker#perform with #{args}"
    GdsApi::GovukHeaders.set_header(:govuk_request_id, args[:request_uuid])

    content_store = args.fetch(:content_store).constantize

    if args[:delete]
      base_path = args.fetch(:base_path)
      content_store.delete_content_item(base_path)
    else
      payload = args.fetch(:payload)
      content_item = ContentItem.find(payload.fetch(:content_item))
      payload_version = payload.fetch(:payload_version)
      presented_payload = Presenters::ContentStorePresenter.present(content_item, payload_version, fallback_order: content_store::DEPENDECY_FALLBACK_ORDER)
      base_path = presented_payload.fetch(:base_path)
      content_store.put_content_item(base_path, presented_payload)
    end

  rescue => e
    handle_error(e)
  end

private

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
