class GraphqlContentItemService


  def something #TODO an actual name
    result = PublishingApiSchema.execute(query, variables: { base_path: encoded_base_path }).to_hash
  
    content_item = if result["errors"] && (unpublished_error = result["errors"].find { |error| error["message"] == "Edition has been unpublished" })
                         unpublished_error["extensions"]
                       else
                         result.dig("data", "edition")
                       end
  end

  def process_content_item!(content_item)
    content_item.compact!
    content_item["details"].compact!
  end
end
