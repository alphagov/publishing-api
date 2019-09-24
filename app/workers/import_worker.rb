class ImportWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :import

  def perform(args = {})
    Commands::V2::RepresentDownstream.new.call(args["content_id"])

    args["draft_base_paths_to_discard"].each do |base_path|
      DownstreamService.discard_from_draft_content_store(base_path)
    end

    live_base_path_to_delete = args["live_base_path_to_delete"]
    if live_base_path_to_delete.present?
      Adapters::ContentStore.delete_content_item(live_base_path_to_delete)
    end
  end
end
