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

private

  def render_content_arrays(array_of_hashes)
    html_content = array_of_hashes.find { |hash| hash[:content_type] == "text/html" }
    govspeak_content = array_of_hashes.find { |hash| hash[:content_type] == "text/govspeak" }

    if html_content.present?
      array_of_hashes
    elsif govspeak_content.present?
      [
        *array_of_hashes,
        {
          content_type: "text/html",
          content: render_govspeak(govspeak_content[:content]),
          rendered_by: "publishing-api",
        },
      ]
    else
      array_of_hashes
    end
  end

  def visit_content_arrays(obj, &block)
    if obj.is_a?(Array) && obj.all?(Hash) && obj.all? { |hash| hash.key?(:content_type) }
      block.call(obj)
    elsif obj.is_a?(Array)
      obj.map { |o| visit_content_arrays(o, &block) }
    elsif obj.is_a?(Hash)
      obj.transform_values do |value|
        visit_content_arrays(value, &block)
      end
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
      ).to_html
    end
  end
end
