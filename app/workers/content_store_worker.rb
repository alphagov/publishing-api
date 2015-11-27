class ContentStoreWorker
  include Sidekiq::Worker

  def perform(args = {})
    args = args.deep_symbolize_keys

    content_store = args.fetch(:content_store).constantize
    base_path = args.fetch(:base_path)

    if args[:delete]
      content_store.delete_content_item(base_path)
    else
      payload = args.fetch(:payload)
      content_store.put_content_item(base_path, payload)
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
