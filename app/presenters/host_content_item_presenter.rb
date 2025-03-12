module Presenters
  class HostContentItemPresenter
    attr_reader :host_content

    def self.present(host_content)
      new(host_content).present
    end

    def initialize(host_content)
      @host_content = host_content
    end

    def present
      {
        title: host_content.title,
        base_path: host_content.base_path,
        document_type: host_content.document_type,
        publishing_app: host_content.publishing_app,
        last_edited_by_editor_id: host_content.last_edited_by_editor_id,
        last_edited_at: host_content.last_edited_at,
        unique_pageviews: host_content.unique_pageviews,
        instances: host_content.instances,
        host_content_id: host_content.host_content_id,
        host_locale: host_content.host_locale,
        primary_publishing_organisation: {
          content_id: host_content.primary_publishing_organisation_content_id,
          title: host_content.primary_publishing_organisation_title,
          base_path: host_content.primary_publishing_organisation_base_path,
        },
      }
    end
  end
end
