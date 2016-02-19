class ContentStoreWorker
  include Sidekiq::Worker

  sidekiq_options queue: :content_store

  def perform(args = {})
    args = args.deep_symbolize_keys

    content_store = args.fetch(:content_store).constantize

    if args[:delete]
      content_store.delete_content_item(args.fetch(:base_path))
    else
      content_item = load_content_item_from(args)
      raise_no_content_item(args) unless content_item
      payload = Presenters::ContentStorePresenter.present(content_item)
      content_store.put_content_item(payload.fetch(:base_path), payload)
    end

  rescue => e
    handle_error(e)
  end

private

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
