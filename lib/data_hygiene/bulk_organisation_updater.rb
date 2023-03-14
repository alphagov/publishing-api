require "csv"

module DataHygiene
  class BulkOrganisationUpdater
    def initialize(filename)
      @filename = filename
      @all_organisations = Queries::GetLinkables.new(document_type: "organisation").call
    end

    def call
      CSV.foreach(filename, liberal_parsing: true, headers: :first_row) do |row|
        process_row(row)
      end
    end

    def self.call(*args)
      new(*args).call
    end

  private

    attr_reader :filename

    def process_row(row)
      document = find_document(row)
      return unless document

      organisations = find_organisations(row)
      update_document(document, organisations)

      path = row.fetch("Path")&.strip
      puts "Sucessfully updated: #{path}"
    end

    def find_document(row)
      path = row.fetch("Path")&.strip
      edition = Edition.find_by(base_path: path)

      if edition.nil?
        puts "error: #{path}: could not find edition"
      else
        edition.document.content_id
      end
    end

    def find_organisations(row)
      organisations = row.fetch("All organisations")&.strip
      return [] unless organisations

      new_organisations = []
      organisations.split(",").map(&:strip).each do |slug|
        organisation = @all_organisations.detect { |org| org.base_path == "/government/organisations/#{slug}" }
        if organisation.nil?
          puts "error: #{slug}: could not find organisation"
        else
          new_organisations << organisation.content_id
        end
      end
      new_organisations
    end

    def update_document(document, organisations)
      Commands::V2::PatchLinkSet.call({
        content_id: document,
        links: { organisations: },
      })
    end
  end
end
