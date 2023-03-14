module DataHygiene
  class BulkOrganisationUpdater
    def initialize(filename)
      @filename = filename
    end

    def call
      CSV.foreach(filename, headers: true) do |row|
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
    end

    def find_document(row)
      path = row.fetch("Path")
      Edition.find_by(base_path: path).document.content_id
    end

    def find_organisations(row)
      all_organisations = Queries::GetLinkables.new(document_type: "organisation").call
      organisations = row.fetch("All organisations")
      return [] unless organisations

      new_organisations = []
      organisations.split(",").map do |slug|
        new_organisations << all_organisations.detect { |organisation| organisation.base_path == "/government/organisations/#{slug}" }.content_id
      end
    end

    def update_document(document, organisations)
      Commands::V2::PatchLinkSet.call({
        content_id: document,
        links: { organisations: },
      })
    end
  end
end
