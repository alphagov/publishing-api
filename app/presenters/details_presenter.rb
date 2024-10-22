require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :edition, :content_item_details, :change_history_presenter

    def initialize(edition, change_history_presenter)
      @edition = edition
      @content_item_details = SymbolizeJSON.symbolize(edition.details)
      @change_history_presenter = change_history_presenter
    end

    def details
      @details ||=
        begin
          updated = recursively_transform_govspeak(content_item_details)
          updated[:change_history] = change_history if change_history.present?
          updated
        end
    end

  private

    def govspeak_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/govspeak" } &&
        wrapped.none? { |hsh| hsh[:content_type] == "text/html" }
    end

    def html_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/html" }
    end

    def recursively_transform_govspeak(obj)
      return obj if !obj.respond_to?(:map) || html_content?(obj)
      return render_govspeak(obj) if govspeak_content?(obj)

      if obj.is_a?(Hash)
        obj.transform_values do |value|
          recursively_transform_govspeak(value)
        end
      else
        obj.map { |o| recursively_transform_govspeak(o) }
      end
    end

    def change_history
      @change_history ||= change_history_presenter&.change_history
    end

    def render_govspeak(value)
      wrapped_value = Array.wrap(value)
      govspeak = {
        content_type: "text/html",
        content: rendered_govspeak(wrapped_value),
      }
      wrapped_value + [govspeak]
    end

    def rendered_govspeak(value)
      Govspeak::Document.new(raw_govspeak(value), govspeak_attributes).to_html
    end

    def raw_govspeak(value)
      value.find { |format| format[:content_type] == "text/govspeak" }[:content]
    end

    def govspeak_attributes
      {
        attachments: content_item_details[:attachments],
        embeds: embedded_editions,
      }
    end

    def embedded_editions
      @embedded_editions ||= begin
        target_content_ids = edition
                               .links
                               .where(link_type: "embed")
                               .pluck(:target_content_id)

        embedded_edition_ids = ::Queries::GetEditionIdsWithFallbacks.call(
          target_content_ids,
          locale_fallback_order: [edition.locale, Edition::DEFAULT_LOCALE].uniq,
          state_fallback_order: %w[published],
        )

        Edition.where(id: embedded_edition_ids).map do |edition|
          {
            content_id: edition.content_id,
            title: edition.title,
            details: edition.details,
            document_type: edition.document_type,
          }
        end
      end
    end
  end
end
