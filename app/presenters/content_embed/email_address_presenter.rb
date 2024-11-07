module Presenters
  module ContentEmbed
    class EmailAddressPresenter < BasePresenter
    private

      def content
        edition.details[:email_address]
      end
    end
  end
end
