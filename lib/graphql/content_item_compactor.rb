class Graphql::ContentItemCompactor
  def compact!(graphql_response)
    graphql_response&.compact!
    graphql_response["details"]&.compact!
    nil
  end
end
