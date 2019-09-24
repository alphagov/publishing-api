class Pagination
  PER_PAGE = 50
  attr_reader :offset, :per_page, :order, :page

  def initialize(options = {})
    @options = options
    @order = order_from_options(options)
    @page = options[:page] || 1
    @per_page = options.fetch(:per_page, PER_PAGE).to_i

    @offset = offset_from_page
  end

  def order_fields
    order.keys.map(&:to_s)
  end

  def pages(total)
    (total.to_f / per_page).ceil
  end

private

  attr_reader :options

  def offset_from_page
    options.fetch(:offset, (page.to_i - 1) * per_page).to_i
  end

  def order_from_options(options)
    order_string = options.fetch(:order, "-public_updated_at")

    orders = order_string.split(",").map(&:strip)
    orders << "id" if orders.none? { |o| o.match("-?id") }

    orders.map do |order|
      if order.start_with?("-")
        field = order[1..-1].to_sym
        direction = :desc
      else
        field = order.to_sym
        direction = :asc
      end
      raise_unless_valid_order_field(field)
      [field, direction]
    end
  end

  def raise_unless_valid_order_field(field)
    return if valid_order_fields.include?(field)

    message = "Invalid order field: #{field}."
    message += " Valid order fields: [#{valid_order_fields.join(', ')}]"

    raise CommandError.new(
      code: 422,
      message: "Invalid order field: #{field}",
      error_details: {
        error: {
          code: 422,
          message: message,
        },
      },
    )
  end

  # These fields have indexes and so we can use them to order results. If we
  # need to add an order field, ensure that it has an index or query performance
  # will be hampered.
  def valid_order_fields
    %i[
      id
      base_path
      content_id
      document_type
      format
      last_edited_at
      locale
      public_updated_at
      publishing_app
      rendering_app
      updated_at
    ]
  end
end
