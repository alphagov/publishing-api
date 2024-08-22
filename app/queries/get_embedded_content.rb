module Queries
  class GetEmbeddedContent
    attr_reader :target_content_id, :states

    def initialize(target_content_id)
      self.target_content_id = target_content_id
      self.states = %i[draft published]
    end

    def call
      if Document.find_by(content_id: target_content_id).nil?
        message = "Could not find an edition to get embedded content for"
        raise CommandError.new(code: 404, message:)
      end

      Presenters::Queries::EmbeddedContentPresenter.present(
        target_content_id,
        host_editions,
      )
    end

  private

    def host_editions
      @host_editions ||= Edition.where(state: states)
        .joins(:links)
        .joins("LEFT JOIN links AS primary_links ON primary_links.edition_id = editions.id AND primary_links.link_type = 'primary_publishing_organisation'")
        .joins("LEFT JOIN documents ON documents.content_id = primary_links.target_content_id")
        .joins("LEFT JOIN editions AS org_editions ON org_editions.document_id = documents.id")
        .where(links: { link_type: embedded_link_type, target_content_id: })
        .select(
          "editions.id, editions.title, editions.base_path, editions.document_type, primary_links.target_content_id AS primary_publishing_organisation_content_id",
          "org_editions.title AS primary_publishing_organisation_title",
          "org_editions.base_path AS primary_publishing_organisation_base_path",
        )
    end

    def embedded_link_type
      "embed"
    end

    attr_writer :target_content_id, :states
  end
end
