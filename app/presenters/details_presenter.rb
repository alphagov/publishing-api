require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :change_history_presenter, :content_embed_presenter, :expanded_link_set_presenter, :locale

    def initialize(content_item_details, change_history_presenter, content_embed_presenter, expanded_link_set_presenter, locale: nil)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
      @change_history_presenter = change_history_presenter
      @content_embed_presenter = content_embed_presenter
      @locale = locale || "en"
    end

    def details
      updated = content_embed(content_item_details).presence || content_item_details
      updated = recursively_transform_govspeak(updated)
      updated[:change_history] = change_history if change_history.present?
      updated
    end

  private

    def parsed_content(array_of_hashes)
      if array_of_hashes.one? { |hash| hash[:content_type] == "text/html" }
        array_of_hashes
      elsif array_of_hashes.one? { |hash| hash[:content_type] == "text/govspeak" }
        render_govspeak(array_of_hashes)
      end
    end

    def recursively_transform_govspeak(obj)
      if obj.is_a?(Array) && obj.all?(Hash) && (parsed_obj = parsed_content(obj))
        parsed_obj
      elsif obj.is_a?(Array)
        obj.map { |o| recursively_transform_govspeak(o) }
      elsif obj.is_a?(Hash)
        obj.transform_values do |value|
          recursively_transform_govspeak(value)
        end
      else
        obj
      end
    end

    def content_embed(content_item_details)
      @content_embed ||= content_embed_presenter&.render_embedded_content(content_item_details)
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
      byebug
      {
        attachments: content_item_details[:attachments],
        locale:,
        contacts: "foo", # TODO - figure out how to derive the below content from `expanded_link_set_presenter`
        # contacts: [{
        #   content_id: "27354c11-eca4-40c2-866f-db097d7f0a5d",
        #   title: "Ryan",
        #   locale: "en",
        #   analytics_identifier: nil,
        #   api_path: nil,
        #   base_path: nil,
        #   document_type: "contact",
        #   public_updated_at: "2025-08-21T15:39:58Z",
        #   schema_name: "contact",
        #   withdrawn: false,
        #   details: {description: "Test", title: "Ryan", contact_form_links: nil, post_addresses: [], email_addresses: [{email: "ryan@example.com"}], phone_numbers: nil},
        #   links: {}
        # }],
      }
    end
  end
end
