class LinkExpansion::AutoReverseLinker
  def initialize(root_edition:, with_drafts:)
    @root_edition = root_edition
    @with_drafts = with_drafts
  end

  def apply(level_one_nodes)
    return unless root_edition_hash

    level_one_nodes.each do |node|
      reverse_type = node.link_type
      next unless rules.is_reverse_link_type?(reverse_type)
      next unless should_link?(reverse_type)

      rules.reverse_to_direct_link_type(reverse_type).each do |direct|
        expanded = rules.expand_fields(root_edition_hash, link_type: direct, draft: with_drafts)
        node.links[direct] = [expanded.merge(links: {})]
      end
    end
  end

private

  attr_reader :root_edition, :with_drafts

  def rules
    ExpansionRules
  end

  def root_edition_hash
    return @root_edition_hash if defined?(@root_edition_hash)

    @root_edition_hash = LinkExpansion::EditionHash.from(root_edition)
  end

  def should_link?(reverse_type)
    Link::PERMITTED_UNPUBLISHED_LINK_TYPES.include?(reverse_type.to_s) ||
      root_edition_hash[:state] != "unpublished"
  end
end
