class FixHighwayCodePublicUpdatedAt < ActiveRecord::Migration[5.0]
  def up
    document = Document.find_by(content_id: content_id)
    edition = document.editions.last
    edition.update!(public_updated_at: "2017-03-01T00:00:00.000+00:00")

    if Rails.env.production?
      Commands::V2::RepresentDownstream.new.([content_id])
    end
  end

  def content_id
    "bbf6c11a-7dc6-4fe6-8dd8-68c09bdbe562"
  end
end
