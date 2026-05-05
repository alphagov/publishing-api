
module CustomRecordInvalidHelper
  def add_error(record, attribute, message, code)
    # record.errors.add(attribute, message)
    # raise CustomRecordInvalid.new(record, error_code: code)
    record.errors.add(attribute, message, error: code)
  end
end