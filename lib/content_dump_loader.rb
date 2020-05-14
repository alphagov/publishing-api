require "csv"
require "zlib"

module ContentDumpLoader
  ContentItem = Struct.new(
    :base_path,
    :content_id,
    :locale,
    :document_type,
    :schema_name,
    :rendering_app,
    :publishing_app,
    :updated_at,
    :details_hash,
    :expanded_links_hash,
    :routes_hash,
    :redirects_hash,
  ) do
    def gone?
      schema_name == "gone" && document_type == "gone"
    end

    def redirect?
      schema_name == "redirect" && document_type == "redirect"
    end
  end

  def self.load(filename)
    Zlib::GzipReader.open(filename) do |file|
      csv = CSV.new(file)
      keys = csv.gets
      csv.each_with_object({}) do |row, hash|
        content_item_hash = Hash[keys.zip(row)].symbolize_keys
        content_item = ContentItem.new(*content_item_hash.values_at(*ContentItem.members))
        content_item.updated_at = Time.zone.parse(content_item.updated_at)
        hash[content_item.base_path.to_sym] = content_item
      end
    end
  end
end
