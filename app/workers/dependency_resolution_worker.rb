class DependencyResolutionWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :dependency_resolution

  def perform(args = {})
    assign_attributes(args.deep_symbolize_keys)

    # downstream translations of this content item
    downstream_content_item(content_id, exclude_locale: locale)

    content_item_dependees.each do |dependent_content_id|
      downstream_content_item(dependent_content_id)
    end
  end

private

  attr_reader :content_id, :locale, :fields, :content_store, :payload_version

  def assign_attributes(args)
    @content_id = args.fetch(:content_id)
    # FIXME: As of December 2016 locale is a optional field to be backwards
    # compatible. By January 2017 it will be safe to make locale required.
    @locale = args[:locale]
    @fields = args.fetch(:fields, []).map(&:to_sym)
    @content_store = args.fetch(:content_store).constantize
    @payload_version = args.fetch(:payload_version)
  end

  def content_item_dependees
    Queries::ContentDependencies.new(content_id: content_id,
                                     fields: fields,
                                     dependent_lookup: Queries::GetDependees.new).call
  end

  def downstream_content_item(dependent_content_id, exclude_locale: nil)
    states = draft? ? %w[draft published unpublished] : %w[published unpublished]
    locales = Queries::LocalesForContentItem.call(dependent_content_id, states)

    locales.each do |locale|
      next if locale == exclude_locale
      if draft?
        downstream_draft(dependent_content_id, locale)
      else
        downstream_live(dependent_content_id, locale)
      end
    end
  end

  def draft?
    content_store == Adapters::DraftContentStore
  end

  def downstream_draft(dependent_content_id, locale)
    DownstreamDraftWorker.perform_async_in_queue(
      DownstreamDraftWorker::LOW_QUEUE,
      content_id: dependent_content_id,
      locale: locale,
      payload_version: payload_version,
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end

  def downstream_live(dependent_content_id, locale)
    DownstreamLiveWorker.perform_async_in_queue(
      DownstreamLiveWorker::LOW_QUEUE,
      content_id: dependent_content_id,
      locale: locale,
      message_queue_update_type: "links",
      payload_version: payload_version,
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end
end
