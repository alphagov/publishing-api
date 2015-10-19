class ContentStoreWorker
  include Sidekiq::Worker

  def perform(args = {})
    args = args.deep_symbolize_keys

    content_store = args.fetch(:content_store).constantize
    base_path = args.fetch(:base_path)
    payload = args.fetch(:payload)

    content_store.call(base_path, payload)
  end
end
