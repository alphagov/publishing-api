class RenameAlphaTaxonLinkType < ActiveRecord::Migration[4.2]
  def up
    alpha_taxon_links = Link.where(link_type: "alpha_taxons")
    link_sets = LinkSet.where(id: alpha_taxon_links.pluck(:link_set_id).uniq)
    link_sets.each do |link_set|
      target_content_ids = link_set.links.where(link_type: "alpha_taxons").pluck(:target_content_id)
      Commands::V2::PatchLinkSet.call(
        {
          content_id: link_set.content_id,
          links: {
            alpha_taxons: [],
            taxons: target_content_ids,
          },
        },
      )
    end
  end
end
