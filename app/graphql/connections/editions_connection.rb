
module Connections
  class EditionsConnection < GraphQL::Pagination::Connection
    def nodes
      load_nodes
      @nodes
    end

    def has_next_page
      load_nodes
      @has_next_page
    end

    def has_previous_page
      load_nodes
      @has_previous_page
    end

    def cursor_for(item)
      encode(item.id.to_s)
    end

    private

    def load_nodes
      # TODO this is all really filthy and needs refactoring...
      #     Also need to support before / last as well as just after / first
      # Could we use Queries::KeysetPagination for this?

      return unless @nodes.nil?

      query = items
      if after.present?
        query = items.where("editions.id <= ?", decode(after))
      end
      query = query.order(id: :desc)

      f = first || 10
      to_grab = after.present? ? f + 2 : f + 1

      grab_bag = query.take(to_grab)

      @has_next_page = grab_bag.count == to_grab

      if after.present?
        @has_previous_page = grab_bag.first.id.to_s == decode(after)
        grab_bag = grab_bag.drop(1)
      else
        @has_previous_page = false
      end

      @nodes = grab_bag.take(f)
    end
  end
end