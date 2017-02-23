require_relative "helpers/delete_content"

class DestroySomeMoreBadWlna < ActiveRecord::Migration[5.0]
  def up
    base_paths = %w(
      /government/world-location-news/235864.pt
      /government/world-location-news/becas-de-ingles-para-jovenes-futbolistas-uruguayos
      /government/world-location-news/english-language-specialist-and-part-of-the-ukti-education-section-visited-ecuador
      /government/world-location-news/new-trade-and-investment-announcements-highlight-strength-of-uk-taiwan-bilateral-relations--2.zh-tw
      /government/world-location-news/--15
      /government/world-location-news/telephone-lines-out-of-order-at-the-british-embassy-in-havana
    )

    ids = Edition.where(base_path: base_paths, publishing_app: "whitehall").joins(:document).distinct.pluck(:content_id)
    Helpers::DeleteContent.destroy_documents_with_links(ids)
  end
end
