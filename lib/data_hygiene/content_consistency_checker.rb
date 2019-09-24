require "gds_api/content_store"

module DataHygiene
  class ContentConsistencyChecker
    attr_reader :errors

    def initialize(content_store, content_dump)
      @content_store = content_store
      @content_dump = content_dump
      @checked_content = Set.new
      @errors = Hash.new { |hash, key| hash[key] = [] }
    end

    def check_editions
      editions_to_check.find_each { |edition| check_edition(edition) }
    end

    def check_content
      unchecked_content.each do |path|
        content_item = content_dump.fetch(path)
        next unless should_check_content_item?(content_item)

        edition = Edition.find_by(
          content_store: content_store,
          base_path: content_item.base_path,
        )

        errors[content_item.base_path] << "No edition available." unless edition
      end
    end

  private

    attr_reader :content_store, :content_dump, :checked_content
    attr_writer :errors

    def unchecked_content
      Set.new(content_dump.keys) - checked_content
    end

    def editions_to_check
      Edition
        .with_document
        .where(content_store: content_store)
    end

    def should_check_content_item?(content_item)
      content_item.schema_name.present? &&
        content_item.content_id.present? &&
        !content_item.gone?
    end

    def get_content_item(path)
      path = path.to_sym
      content_item = content_dump.fetch(path)
      checked_content.add?(path)
      content_item
    rescue KeyError
      nil
    end

    def hash_field(object)
      Digest::SHA1.hexdigest(
        JSON.generate(object),
      )
    end

    def draft?
      content_store.to_s == "draft"
    end

    def check_edition(edition)
      return unless edition.base_path

      path = edition.base_path

      content_item = get_content_item(edition.base_path)

      unless content_item
        unless edition.gone?
          errors[path] << "Content is missing from the content store."
        end

        return
      end

      return if edition.updated_at > content_item.updated_at

      if edition.redirect?
        unless content_item.redirect?
          errors[path] << "Content is not a redirect in the content store."
        end
      elsif edition.gone?
        unless content_item.gone?
          errors[path] << "Content is not gone in the content store."
        end
      else
        fields = %i[content_id locale rendering_app publishing_app schema_name document_type]
        fields.each do |field|
          edition_value = edition.public_send(field)
          content_item_value = content_item.public_send(field)

          if edition_value != content_item_value
            errors[path] << "Edition #{field} (#{edition_value}) does not match content store (#{content_item_value})."
          end
        end

        edition_presenter = Presenters::EditionPresenter.new(edition, draft: draft?)

        hash_fields = %i[routes redirects]
        hash_fields.each do |field|
          edition_value = hash_field(edition.public_send(field))
          content_item_value = content_item.public_send("#{field}_hash")

          if edition_value != content_item_value
            errors[path] << "Edition #{field} hash does not match content store hash."
          end
        end

        rendered_details = edition_presenter.rendered_details
        if hash_field(rendered_details) != content_item.details_hash
          errors[path] << "Edition details hash does not match content store hash."
        end
      end
    end
  end
end
