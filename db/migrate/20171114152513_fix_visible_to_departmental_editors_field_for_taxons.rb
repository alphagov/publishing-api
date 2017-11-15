class FixVisibleToDepartmentalEditorsFieldForTaxons < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
    published_taxons = Edition.where(document_type: "taxon").where(state: "published")
    content_ids = published_taxons.joins(:document).pluck(:content_id)

    published_taxons.each do |t|
      updated_details = t.details.merge(visible_to_departmental_editors: true)
      t.update(details: updated_details)
    end

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.call(content_ids)
    end

    puts "Updated #{published_taxons.count} taxon editions."
  end
end
