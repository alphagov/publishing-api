module Queries
  module ExpansionRules
    extend self

    def expansion_fields(link_type)
      custom(link_type) || default_fields
    end

    def recurse?(link_type)
      recursive_link_types.include?(link_type)
    end

  private

    def recursive_link_types
      [:parent]
    end

    def custom(link_type)
      {
        topical_event: default_fields + [:details]
      }[link_type]
    end

    def default_fields
      [
        :analytics_identifier,
        :api_url,
        :base_path,
        :content_id,
        :description,
        :locale,
        :title,
        :web_url
      ]
    end
  end
end
