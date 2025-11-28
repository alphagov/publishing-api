require "govspeak"

class GovspeakDetailsRenderer
  def initialize(details, locale: nil)
    @details = details
    @locale = locale || Edition::DEFAULT_LOCALE
  end

  def render
    visit_content_arrays(@details) do |content_array|
      render_content_arrays(content_array)
    end
  end

  def remove_content_rendered_by_publishing_api
    visit_content_arrays(@details) do |content_array|
      content_array.reject { |content_hash| content_hash[:rendered_by] == "publishing-api" }
    end
  end

private

  def render_content_arrays(array_of_hashes)
    case array_of_hashes
    in [*, { content_type: "text/html" }, *]
      array_of_hashes
    in [*, { content_type: "text/govspeak", content: govspeak_content }, *]
      array_of_hashes + [
        {
          content_type: "text/html",
          content: render_govspeak(govspeak_content),
          rendered_by: "publishing-api",
          govspeak_version: Gem.loaded_specs["govspeak"]&.version&.to_s || "unknown",
        },
      ]
    else
      array_of_hashes
    end
  end

  def visit_content_arrays(obj, &block)
    case obj
    in [{ content_type: String }, *]
      block.call(obj)
    in Array
      obj.map { |o| visit_content_arrays(o, &block) }
    in Hash
      obj.transform_values { |value| visit_content_arrays(value, &block) }
    else
      obj
    end
  end

  def render_govspeak(value)
    ActiveSupport::Notifications.instrument(
      "govspeak.to_html",
      truncated_govspeak: value&.truncate(100),
      govspeak_size: value&.bytesize,
    ) do
      Govspeak::Document.new(
        value,
        attachments: @details[:attachments],
        locale: @locale,
        rendered_by: "publishing-api",
      ).to_html
    end
  end
end
