require "govspeak"

class GovspeakDetailsRenderer
  def initialize(details, locale: nil)
    @details = details
    @locale = locale || Edition::DEFAULT_LOCALE
  end

  def render
    recursively_transform_govspeak(@details)
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

  def render_govspeak(value)
    wrapped_value = Array.wrap(value)
    govspeak = {
      content_type: "text/html",
      content: rendered_govspeak(wrapped_value),
    }
    wrapped_value + [govspeak]
  end

  def rendered_govspeak(value)
    raw = raw_govspeak(value)
    ActiveSupport::Notifications.instrument(
      "govspeak.to_html",
      truncated_govspeak: raw&.truncate(100),
      govspeak_size: raw&.bytesize,
    ) do
      Govspeak::Document.new(raw, govspeak_attributes).to_html
    end
  end

  def raw_govspeak(value)
    value.find { |format| format[:content_type] == "text/govspeak" }[:content]
  end

  def govspeak_attributes
    {
      attachments: @details[:attachments],
      locale: @locale,
    }
  end
end
