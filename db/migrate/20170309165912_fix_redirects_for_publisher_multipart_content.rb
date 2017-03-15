class FixRedirectsForPublisherMultipartContent < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  BASE_PATHS_FOR_PARTED_CONTENT_WITH_EXACT_REDIRECT_TYPE = [
    "/accredited-electrical-and-electronic-equipment-producer-compliance-scheme-scotland",
    "/air-conditioning-system-energy-assessor-accreditation-england-wales",
    "/business-legal-structures",
    "/domestic-energy-assessor-existing-buildings",
    "/energy-assessor-england-and-wales",
    "/family-visit-visa",
    "/insolvency-practitioner-authorisation-ni",
    "/insolvency-practitioner-authorisations-england-scotland-wales",
    "/non-domestic-energy-assessor-accreditation",
    "/on-construction-dea-accreditation",
    "/operational-ratings-assessor-accreditation-england-wales",
    "/set-up-and-run-limited-liability-partnership",
    "/set-up-and-run-limited-partnership",
    "/set-up-business-uk",
    "/tv-dealer-notifications",
  ].freeze

  def unpublishings
    unpublished_editions.map(&:unpublishing)
  end

  def unpublished_editions
    Edition
      .where('base_path IN (?)', BASE_PATHS_FOR_PARTED_CONTENT_WITH_EXACT_REDIRECT_TYPE)
      .where(state: "unpublished")
      .where(publishing_app: "publisher")
      .where("updated_at > '2017-01-20'")
      .where("updated_at < '2017-02-27'")
  end

  def up
    unpublishings.each do |u|
      prefix_redirects = u.redirects
      prefix_redirects.each { |r| r[:type] = "prefix" }
      u.update_attributes!(redirects: prefix_redirects)
    end

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(unpublished_editions.map(&:content_id))
    end
  end
end
