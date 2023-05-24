module DiagramGenerator
  class DocumentObjectDiagram
    def initialize(document_id = nil)
      @document = document_id ? Document.find(document_id) : Document.last
      # avoid duplicates
      @emitted_objects = []
      @emitted_links = []
    end

    def draw
      # suppress sql
      old_log_level = ActiveRecord::Base.logger.level
      ActiveRecord::Base.logger.level = Logger::INFO

      puts "-" * 60

      puts "@startuml"
      puts "node PublishingApi {"
      emit_object(@document, %i[content_id])

      @document.editions.each do |edition|
        dump_edition(@document, edition)
      end

      puts "}"
      puts "@enduml"

      puts "-" * 60

      ActiveRecord::Base.logger.level = old_log_level
    end

    private

    def emit_object(obj, fields)
      key = object_key(obj)
      unless @emitted_objects.include? key
        @emitted_objects << key
        puts "object \"#{object_name(obj)}\" as #{object_key(obj)} {"
        fields.each do |f|
          if obj[f].is_a? Time
            puts "  #{f}: #{obj[f].to_fs(:short)}"
          else
            puts "  #{f}: #{obj[f]}"
          end
        end
        puts "}"
      end
    end

    def emit_link(from, to, link)
      from_key = object_key(from)
      to_key = object_key(to)
      unless @emitted_links.include?([from_key, to_key])
        puts "#{object_key(from)} #{link} #{object_key(to)}"
        @emitted_links << [from_key, to_key]
      end
    end

    def object_key(obj)
      "pubapi_#{obj.class.name}_#{obj.id}"
    end

    def object_name(obj)
      "#{obj.class.name}:#{obj.id}"
    end

    def dump_edition(document, edition)
      emit_object(edition, %i[title public_updated_at publishing_app rendering_app update_type phase document_type schema_name first_published_at state user_facing_versions content_store published_at major_published_at publishing_api_first_published_at ])

      emit_link(document, edition, "*--")

      if (unpublishing = edition.unpublishing)
        emit_object(unpublishing, %i[type explanation alternative_path unpublished_at redirects])
        emit_link(edition, unpublishing, "*-")
      end
    end

  end
end
