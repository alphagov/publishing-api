class ContentStoreWorker
  include Sidekiq::Worker

  def perform(args = {})
    args = args.deep_symbolize_keys

    content_store = args.fetch(:content_store).constantize
    content_item = load_content_item_from(args)
    base_path = content_item.base_path

    if args[:delete]
      content_store.delete_content_item(base_path)
    else
      payload = Presenters::ContentStorePresenter.present(content_item)
      content_store.put_content_item(base_path, payload)
    end

  rescue => e
    handle_error(e)
  end

private

  def load_content_item_from(args)
    case
    when args[:draft_content_item_id]
      DraftContentItem.find(args[:draft_content_item_id])
    when args[:live_content_item_id]
      LiveContentItem.find(args[:live_content_item_id])
    else
      raise "a live or a draft content item is needed"
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
end
