require 'gds_api/content_store'

class ContentConsistencyChecker
  attr_reader :errors

  ContentItem = Struct.new(:base_path,
                           :content_id,
                           :locale,
                           :document_type,
                           :schema_name,
                           :rendering_app,
                           :publishing_app,
                           :updated_at) do
    def gone?
      schema_name == "gone" && document_type == "gone"
    end

    def redirect?
      schema_name == "redirect" && document_type == "redirect"
    end
  end

  def initialize(content_store, content_dump)
    @content_store = content_store
    @content_dump = load_content_dump(content_dump)
    @remaining_content = Set.new(@content_dump.keys)
    @errors = Hash.new { |hash, key| hash[key] = [] }
  end

  def check_editions
    editions_to_check.limit(10000).find_each do |edition|
      check_edition(edition)
    end
  end

  def check_content
    @remaining_content.each do |path|
      content_item = @content_dump.fetch(path)
      next if content_item["content_id"].nil?
      next if content_item["schema_name"] == "gone"
      next if content_item["schema_name"].nil? || content_item["schema_name"].empty?

      edition = Edition.find_by(
        content_store: content_store,
        base_path: content_item["base_path"]
      )
      next if edition

      @errors[content_item["base_path"]] << "No edition available."
    end
  end

private

  attr_reader :content_store

  def editions_to_check
    Edition
      .with_document
      .where(content_store: content_store)
  end

  def load_content_dump(filename)
    content_dump = {}

    Zlib::GzipReader.open(filename) do |file|
      csv = CSV.new(file)
      keys = csv.gets
      csv.each do |row|
        content_item_hash = Hash[keys.zip(row)].symbolize_keys
        content_item = ContentItem.new(*content_item_hash.values_at(*ContentItem.members))
        content_item.updated_at = Time.parse(content_item.updated_at)
        base_path = content_item.base_path
        content_dump[base_path.to_sym] = content_item
      end
    end

    content_dump
  end

  def get_content_item(path)
    begin
      path = path.to_sym
      content_item = @content_dump.fetch(path)
      @remaining_content.delete?(path)
      content_item
    rescue KeyError
      nil
    end
  end

  def check_edition(edition)
    return unless edition.base_path

    path = edition.base_path

    content_item = get_content_item(edition.base_path)

    unless content_item
      unless edition.gone?
        @errors[path] << "Content is missing from the content store."
      end

      return
    end

    return if edition.updated_at > content_item.updated_at

    if edition.redirect?
      unless content_item.redirect?
        @errors[path] << "Content is not a redirect in the content store."
      end
    elsif edition.gone?
      unless content_item.gone?
        @errors[path] << "Content is not gone in the content store."
      end
    else
      fields = [:content_id, :locale, :rendering_app, :publishing_app, :schema_name, :document_type]
      fields.each do |field|
        edition_value = edition.send(field)
        content_item_value = content_item.send(field)

        if edition_value != content_item_value
          @errors[path] << "Edition #{field} (#{edition_value}) does not match content store (#{content_item_value})."
        end
      end
    end
  end
end
