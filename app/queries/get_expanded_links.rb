module Queries
  class GetExpandedLinks
    def self.call(content_id, locale, with_drafts: true, generate: false)
      self.new(content_id, locale, with_drafts, generate).call
    end

    def call
      expanded_links = generate ? nil : links_from_storage

      if expanded_links
        stored_links_response(expanded_links)
      else
        generate_links_response
      end
    end

  private

    attr_reader :content_id, :locale, :with_drafts, :generate

    def initialize(content_id, locale, with_drafts, generate)
      @content_id = content_id
      @locale = locale
      @with_drafts = with_drafts
      @generate = generate
    end

    def links_from_storage
      ExpandedLinks.find_by(
        content_id: content_id,
        locale: locale,
        with_drafts: with_drafts,
      )
    end

    def generate_links_response
      # When we generate the links we also return the link set version, this
      # is a deprecated field as it doesn't adequately capture the version of
      # the expanded links (since they are populated by edition and link set)
      link_set_version = LinkSet.find_by(content_id: content_id)&.stale_lock_version || 0

      expanded_links = Presenters::Queries::ExpandedLinkSet.by_content_id(
        content_id,
        locale: locale,
        with_drafts: with_drafts,
      ).links

      check_content_id_is_known if expanded_links.empty?

      response(expanded_links, Time.now.utc, link_set_version)
    end

    def stored_links_response(expanded_links)
      response(
        expanded_links.expanded_links,
        expanded_links.updated_at,
      )
    end

    def response(expanded_links, generated_date, version = nil)
      response = {
        generated: generated_date.iso8601,
        expanded_links: expanded_links,
      }
      response[:version] = version if version
      response
    end

    def check_content_id_is_known
      return if Document.exists?(content_id: content_id) || LinkSet.exists?(content_id: content_id)

      message = "Could not find links for content_id: #{content_id}"
      raise CommandError.new(code: 404, message: message)
    end
  end
end
