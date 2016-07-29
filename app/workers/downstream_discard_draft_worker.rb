class DownstreamDiscardDraftWorker
  attr_reader :base_path, :content_id, :payload_version, :update_dependencies

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    if content_exists_at_base_path?
      raise CommandError.new(
        code: 409,
        message: "Cannot delete #{base_path} from draft store, as there is a published or draft item with that base_path"
      )
    end

    delete_from_draft_content_store if base_path
    enqueue_dependencies if update_dependencies
  end

private

  def assign_attributes(attributes)
    @base_path = attributes.fetch(:base_path)
    @content_id = attributes.fetch(:content_id)
    @payload_version = attributes.fetch(:payload_version)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def content_exists_at_base_path?
    return false unless base_path
    ContentItemFilter.filter(
      base_path: base_path,
      state: %w(draft published),
    ).exists?
  end

  def delete_from_draft_content_store
    draft_content_store.delete_content_item(base_path)
  end

  def draft_content_store
    Adapters::DraftContentStore
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: draft_content_store,
      # @TODO - Check whether this is a sufficient array of fields to update dependencies
      fields: [:content_id],
      content_id: content_id,
      payload_version: payload_version,
    )
  end
end
