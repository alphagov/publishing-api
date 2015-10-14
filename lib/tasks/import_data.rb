require "json"

module Tasks
  class ImportData
    def initialize(file:, total_lines:, stdout:, draft:)
      @file = file
      @total_lines = total_lines
      @stdout = stdout
      @draft = draft
    end

    def import_all
      file.each.with_index(1) do |json, index|
        parsed_json = JSON.parse(json).deep_symbolize_keys

        updated_at = parsed_json.fetch(:updated_at)
        content_item_hash = parsed_json.fetch(:content_item)
        content_id = content_item_hash.fetch(:content_id)
        locale = content_item_hash.fetch(:locale)

        unless derived_content_class.where(content_id: content_id, locale: locale).exists?
          Event.create!(
            action: action,
            payload: content_item_hash,
            created_at: updated_at,
            updated_at: updated_at,
          )

          command_class.new(content_item_hash).call(downstream: false)
        end

        print_progress(index, total_lines)
      end

      stdout.puts
    end

  private

    attr_reader :file, :total_lines, :stdout, :draft

    def print_progress(completed, total)
      percent_complete = ((completed.to_f / total) * 100).round
      percent_remaining = 100 - percent_complete

      stdout.print "\r"
      stdout.flush
      stdout.print "Progress [#{"=" * percent_complete}>#{"." * percent_remaining}] (#{percent_complete}%)"
      stdout.flush
    end

    def action
      command_class.name.split("::")[-1]
    end

    def command_class
      if draft
        Commands::PutDraftContentWithLinks
      else
        Commands::PutContentWithLinks
      end
    end

    def derived_content_class
      if draft
        DraftContentItem
      else
        LiveContentItem
      end
    end
  end
end
