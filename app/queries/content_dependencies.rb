module Queries
  # This class resolves the depencies for a given subject content item with
  # a provided content_id and locale
  #
  # There are 3 types of dependency this resolves:
  # 1 - Content items that are linked to the subject of dependency resolution
  #     (eg for a subject of a if b has a link to a b will be returned),
  #     for certain link types these are recursed forming a tree structure.
  # 2 - Content Items which have an automoatic reverse link to the subject.
  #     These are items this subject links to and is represented reciprocally
  #     in the item linked to. eg if our subject (A) has a parent of B, B would
  #     automatically have a link to A of type children.
  # 3 - Translations, for the subject all locales except the one provided is
  #     added as dependencies, as well as all translations of the content_ids
  #     found.
  class ContentDependencies
    def initialize(content_id:, locale:, state_fallback_order:)
      @content_id = content_id
      @locale = locale
      @state_fallback_order = state_fallback_order
    end

    def call
      content_ids = linked_to(content_id) + automatic_reverse_links(content_id) + [content_id]
      with_locales = Queries::LocalesForContentItems.call(content_ids.uniq, state_fallback_order)
      calling_item = locale ? [content_id, locale] : nil
      with_locales - [calling_item]
    end

  private

    attr_reader :content_id, :locale, :state_fallback_order

    def linked_to(content_id)
      Queries::LinkedTo.new(content_id, DependeeExpansionRules).call
    end

    def automatic_reverse_links(content_id)
      link_types = DependentExpansionRules.reverse_recursive_types
      Link.joins(:link_set)
        .where(link_sets: { content_id: content_id }, link_type: link_types)
        .pluck(:target_content_id)
    end
  end
end
