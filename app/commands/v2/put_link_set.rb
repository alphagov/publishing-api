module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        link_set = LinkSet.create_or_replace(link_params.except(:links)) do |link_set|
          link_set.version += 1
          link_set.links = merge_links(link_set.links, link_params.fetch(:links))
        end

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

      def merge_links(base_links, new_links)
        base_links
          .merge(new_links)
          .reject {|_, links| links.empty? }
      end
    end
  end
end
