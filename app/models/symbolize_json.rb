module SymbolizeJSON
  def self.included(model)
    model.columns.each do |column|
      next unless column.sql_type.match(/^jsonb?$/i)

      model.class_eval do
        define_method(column.name) do
          SymbolizeJSON.symbolize(self[column.name])
        end
      end
    end
  end

  def self.symbolize(value)
    case value
    when Array
      value.map { |element| symbolize(element) }
    when Hash
      value.each_with_object({}) do |(k, v), new_hash|
        new_hash[k.to_sym] = symbolize(v)
      end
    when ActiveSupport::TimeWithZone
      value.iso8601
    else
      value
    end
  end
end
