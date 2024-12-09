# frozen_string_literal: true

module Types
  class NewsArticleType < Types::EditionType
    def self.document_types = %w[
      government_response
      news_story
      press_release
      world_news_story
    ]
  end
end
