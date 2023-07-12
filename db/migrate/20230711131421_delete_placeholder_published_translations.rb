require_relative "helpers/delete_content"

class DeletePlaceholderPublishedTranslations < ActiveRecord::Migration[7.0]
  class NotPlaceholderTranslationError < StandardError; end

  def up
    base_paths = %w[
      /world/organisations/british-embassy-riga/about/complaints-procedure.lv
      /world/organisations/british-embassy-in-costa-rica.es
      /world/organisations/department-for-international-trade-argentina.es-419
      /world/organisations/department-for-international-trade-czech-republic.cs
      /world/organisations/department-for-international-trade-ecuador.es-419
      /world/organisations/department-for-international-trade-kazakhstan.ru
      /world/organisations/department-for-international-trade-latvia.lv
      /world/organisations/department-for-international-trade-morocco.ar
      /world/organisations/department-for-international-trade-pakistan.ur
      /world/organisations/department-for-international-trade-portugal.pt
      /world/organisations/department-for-international-trade-south-korea.ar
      /world/organisations/department-for-international-trade-taiwan.zh-tw
      /world/organisations/department-for-international-trade-thailand.th
      /world/organisations/department-for-international-trade-united-arab-emirates.ar
      /world/organisations/uk-science-and-innovation-network.hi
      /world/organisations/uk-science-innovation-network-in-chile.es-419
      /government/world/organisations/british-embassy-colombia.es
      /government/world/organisations/dfid-china.zh-tw
      /world/organisations/dfid-china.zh
      /world/organisations/dfid-middle-east-and-north-africa.ar
      /world/organisations/dfid-bangladesh.bn
      /world/organisations/dfid-pakistan.ur
      /world/organisations/dfid-drc.fr
      /world/organisations/dfid-india.hi
    ]

    editions = Edition.where(base_path: base_paths, state: "published")

    raise NotPlaceholderTranslationError if editions.any? { |edition| !edition.schema_name.include?("placeholder") }

    Helpers::DeleteContent.destroy_edition_supporting_objects(editions)

    editions.destroy_all
  end
end
