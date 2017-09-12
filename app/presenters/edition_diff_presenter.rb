module Presenters
  class EditionDiffPresenter
    def self.call(edition)
      attributes = {}
      return attributes unless edition.present?

      Edition::TOP_LEVEL_FIELDS.each do |field|
        attributes[field.to_sym] = edition.public_send(field)
      end

      attributes[:links] = {}

      edition.links.each do |link|
        link_type = link.link_type.to_sym
        attributes[:links][link_type] ||= []
        attributes[:links][link_type] << link.target_content_id
      end

      attributes[:change_note] = edition.change_note&.note || {}

      attributes
    end
  end
end
