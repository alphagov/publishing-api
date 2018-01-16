require_relative "helpers/delete_content"

class DeleteTranslationWithWrongLocale < ActiveRecord::Migration[5.1]
  def up
    content_ids = [
      #/government/publications/flexibly-accessed-pension-payment-repayment-claim-tax-year-p55.cy
      "a6599b02-ca7f-4a1f-bcfb-a7b54b71a030",
      #/government/publications/flexibly-accessed-pension-payment-repayment-claim-tax-year-2015-2016-p55.cy
      "7b01d966-2bb2-4be8-9ee4-0da8a4f8c010",
    ]

    Helpers::DeleteContent.destroy_documents_with_links(content_ids)
  end
end
