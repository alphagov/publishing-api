module Sources
  class EditionSource < GraphQL::Dataloader::Source
    def fetch(content_ids)
      content_ids.map do |content_id|
        Queries::GetEditionForContentStore.call(content_id, "en")
      end
    end
  end
end