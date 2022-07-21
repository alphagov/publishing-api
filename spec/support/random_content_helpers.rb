require "govuk_schemas"

module RandomContentHelpers
  def generate_random_edition(base_path)
    GovukSchemas::RandomExample.for_schema(publisher_schema: "placeholder") do |content|
      content.merge(
        base_path: base_path,
        update_type: "major",

        title: "Something not empty", # TODO: make schemas validate title length
        routes: [
          { path: base_path, type: "prefix" },
        ],
        redirects: [],
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
