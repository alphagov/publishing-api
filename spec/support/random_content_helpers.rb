require "govuk_schemas"

module RandomContentHelpers
  def build_random_example(seed)
    schema = GovukSchemas::Schema.find(publisher_schema: "generic")

    # The "generic" schema includes ALL document types.
    #
    # We don't want to generate editions with special document_type values like "redirect"
    # as these may be handled by publishing API in special ways which confuse some tests
    schema["properties"]["document_type"]["enum"].reject! do |document_type|
      %w[gone redirect vanish].include?(document_type) || document_type.start_with?("content_block_")
    end

    GovukSchemas::RandomExample.new(schema:, seed:)
  end

  def generate_random_edition(random_example, base_path)
    random_example.payload do |content|
      content.merge(
        "base_path" => base_path,
        "update_type" => "major",

        "title" => "Something not empty", # TODO: make schemas validate title length
        "routes" => [
          { "path" => base_path, "type" => "prefix" },
        ],
        "redirects" => [],
      )
    end
  end

  def random_content_failure_message(response, edition)
    <<-DOC
    Failed #{response.request.method} #{response.request.fullpath}

    Content:
    #{JSON.pretty_generate(edition)}

    Response:
    #{JSON.pretty_generate(parsed_response)}"
    DOC
  end
end
