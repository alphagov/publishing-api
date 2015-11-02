module SymbolizeJSON
  def self.included(model)
    model.columns.each do |column|
      next unless column.sql_type == "json"

      define_method(column.name) do
        SymbolizeJSON.symbolize(self[column.name])
      end
    end
  end

  def self.symbolize(value)
    case value
    when Array
      value.map { |element| symbolize(element) }
    when Hash
      value.deep_symbolize_keys
    else
      value
    end
  end
end
