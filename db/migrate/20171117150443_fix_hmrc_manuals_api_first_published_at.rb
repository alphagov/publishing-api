require_relative "helpers/february29th2016"

class FixHmrcManualsApiFirstPublishedAt < ActiveRecord::Migration[5.1]
  def up
    publishing_app = "hmrc-manuals-api"

    manual_dates = {
      "vat-government-and-public-bodies"                 => "24 August 2012",
      "business-income-manual"                           => "22 November 2013",
      "employment-income-manual"                         => "22 May 2014",
      "pensions-tax-manual"                              => "27 March 2015",
      "employee-tax-advantaged-share-scheme-user-manual" => "26 August 2015",
      "scottish-taxpayer-technical-guidance"             => "26 October 2015",
    }

    manual_dates.each do |manual, date|
      puts manual

      content_ids = Edition
        .where(publishing_app: publishing_app)
        .where("base_path like '/hmrc-internal-manuals/#{manual}%'")
        .joins(:document)
        .pluck(:content_id)
        .uniq

      datetime = DateTime.parse("9am on #{date}")

      Helpers::February29th2016.replace_first_published_at(
        content_ids.map { |c| [c, datetime] },
        where_conditions: { publishing_app: publishing_app },
      )
    end
  end
end
