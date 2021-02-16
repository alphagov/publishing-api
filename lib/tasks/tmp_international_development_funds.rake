namespace :international_development_funds do
  desc "Republishes international development funds with new 'value_of_funding' values"
  task update_value_of_funding: :environment do
    Edition.where(document_type: "international_development_fund").each do |edition|
      value_of_funding = edition.details.dig(:metadata, :value_of_funding) || []
      next unless value_of_funding.include?("up-to-100000")

      other_values = value_of_funding.reject { |val| val == "up-to-100000" }
      edition.details = edition.details.deep_merge({
        metadata: {
          value_of_funding: other_values.unshift("10001-to-100000"),
        },
      })
      edition.save!
    end
  end
end
