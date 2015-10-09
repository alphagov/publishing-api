module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        content_id = links_params.fetch(:content_id)

        if (link_set = LinkSet.find_by(content_id: content_id))
          link_set.links = link_set.links
            .merge(links_params.fetch(:links))
            .reject {|_, links| links.empty? }

          link_set.save!

          Success.new(links: link_set.links)
        else
          raise CommandError.new(
            code: 404,
            message: "Link set with content_id '#{content_id}' not found"
          )
        end
      end

    private
      def validate!
        raise CommandError.new(
          code: 422,
          message: "Links are required",
          error_details: {
            error: {
              code: 422,
              message: "Links are required",
              fields: {
                links: ["are required"],
              }
            }
          }
        ) unless links_params[:links].present?
      end

      def links_params
        payload
      end
    end
  end
end
