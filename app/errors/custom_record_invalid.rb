class CustomRecordInvalid < ActiveRecord::RecordInvalid
  attr_reader :error_code

  def initialize(record, error_code:)
    @error_code = error_code
    super(record)
  end
end
