module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        content_id = link_params.fetch(:content_id)

        link_set = LinkSet.find_or_initialize_by(content_id: content_id)

        link_set.links = link_set.links
          .merge(link_params.fetch(:links))
          .reject {|_, links| links.empty? }

        link_set.save!

        Success.new(links: link_set.links)
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
        ) unless link_params[:links].present?
      end

      def link_params
        payload
      end
    end
  end
end
