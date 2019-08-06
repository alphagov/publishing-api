module Queries
  # This class resolves the dependencies for a given content_id and locale
  #
  # There are 3 types of dependency this resolves:
  # 1 - Documents that are linked to the subject of dependency resolution
  #     (eg for a subject of a if b has a link to a b will be returned),
  #     for certain link types these are recursed forming a tree structure.
  # 2 - Documents which have an automatic reverse link to the subject.
  #     These are items this subject links to and is represented reciprocally
  #     in the item linked to. eg if our subject (A) has a parent of B, B would
  #     automatically have a link to A of type children.
  # 3 - Translations, for the subject all locales except the one provided is
  #     added as dependencies, as well as all translations of the content_ids
  #     found.
  class ContentDependencies
    def initialize(content_id:, locale:, content_stores:)
      @content_id = content_id
      @locale = locale
      @content_stores = content_stores
    end

    def with_drafts?
      content_stores.include?("draft")
    end

    def call
      content_ids = dependency_resolution.dependencies + [content_id]
      with_locales = Queries::LocalesForEditions.call(content_ids, content_stores)
      calling_item = locale ? [content_id, locale] : nil
      with_locales - [calling_item]
    end

  private

    attr_reader :content_id, :locale, :content_stores

    def document_type
      edition[:document_type]
    end

    def dependency_resolution
      @dependency_resolution ||= DependencyResolution.new(
        content_id,
        locale: locale,
        with_drafts: with_drafts?
      )
    end

    def edition
      GetEditionForContentStore.call(content_id, locale, with_drafts?)
    end
  end
end
