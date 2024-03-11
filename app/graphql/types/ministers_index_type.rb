# frozen_string_literal: true

module Types
  class MinistersIndexType < Types::EditionType
    description "Ministers index page"
    field :cabinet_ministers, [PersonType]
    field :also_attends_cabinet, [PersonType]
    field :ministerial_departments, [OrganisationType]
    field :house_of_commons_whips, [PersonType]
    field :junior_lords_of_the_treasury_whips, [PersonType]
    field :assistant_whips, [PersonType]
    field :house_of_lords_whips, [PersonType]
    field :baronesses_and_lords_in_waiting_whips, [PersonType]

    def cabinet_ministers
      linked_editions("ordered_cabinet_ministers")
    end

    def also_attends_cabinet
      linked_editions("ordered_also_attends_cabinet")
    end

    def ministerial_departments
      linked_editions("ordered_ministerial_departments")
    end

    def house_of_commons_whips
      linked_editions("ordered_house_of_commons_whips")
    end

    def junior_lords_of_the_treasury_whips
      linked_editions("ordered_junior_lords_of_the_treasury_whips")
    end

    def assistant_whips
      linked_editions("ordered_assistant_whips")
    end

    def house_of_lords_whips
      linked_editions("ordered_house_of_lords_whips")
    end

    def baronesses_and_lords_in_waiting_whips
      linked_editions("ordered_baronesses_and_lords_in_waiting_whips")
    end

  private

    def linked_editions(link_type)
      link_set_links_from(link_types: [link_type]).map do |link|
        Queries::GetEditionForContentStore.call(link[:target_content_id], "en")
      end
    end
  end
end
