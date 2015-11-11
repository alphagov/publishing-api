module Queries
  module GetLinkSet
    def self.call(content_id)
      if (link_set = LinkSet.find_by(content_id: content_id))
        Presenters::Queries::LinkSetPresenter.present(link_set)
      else
        error_details = {
          error: {
            code: 404,
            message: "Could not find link set with content_id: #{content_id}"
          }
        }

        raise CommandError.new(code: 404, error_details: error_details)
      end
    end
  end
end
