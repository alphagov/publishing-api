SELECT "links"."link_type", "links"."target_content_id",
        EXISTS(
          SELECT nested_links.id
          FROM links AS nested_links
          INNER JOIN link_sets AS nested_link_sets
          ON nested_link_sets.id = nested_links.link_set_id
          WHERE
          nested_link_sets.content_id = links.target_content_id
          AND (
              (links.link_type = 'associated_taxons' AND nested_links.link_type IN ('associated_taxons'))
                  OR (links.link_type = 'parent' AND nested_links.link_type IN ('parent'))
                  OR (links.link_type = 'parent_taxons' AND nested_links.link_type IN ('parent_taxons', 'root_taxon'))
                  OR (links.link_type = 'taxons' AND nested_links.link_type IN ('root_taxon', 'parent_taxons'))
                  OR (links.link_type = 'ordered_related_items' AND nested_links.link_type IN ('mainstream_browse_pages'))
                  OR (links.link_type = 'ordered_related_items_overrides' AND nested_links.link_type IN ('taxons'))
                  OR (links.link_type = 'ordered_ministerial_departments' AND nested_links.link_type IN ('ordered_ministers', 'ordered_roles'))
                  OR (links.link_type = 'historical_accounts' AND nested_links.link_type IN ('person'))
                  OR (links.link_type = 'main_office' AND nested_links.link_type IN ('contact'))
                  OR (links.link_type = 'home_page_offices' AND nested_links.link_type IN ('contact'))
                  OR (links.link_type = 'worldwide_organisation' AND nested_links.link_type IN ('sponsoring_organisations', 'world_locations')))
          LIMIT 1
        )
      ,
        EXISTS(
          SELECT nested_links.id
          FROM links AS nested_links
          INNER JOIN link_sets AS nested_link_sets
          ON nested_link_sets.id = nested_links.link_set_id
          WHERE
          nested_links.target_content_id = links.target_content_id
          AND
              ((links.link_type = 'ordered_also_attends_cabinet' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_assistant_whips' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_baronesses_and_lords_in_waiting_whips' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_board_members' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_cabinet_ministers' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_chief_professional_officers' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_house_lords_whips' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_house_of_commons_whips' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_junior_lords_of_the_treasury_whips' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_military_personnel' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_ministers' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'office_staff' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'primary_role_person' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'secondary_role_person' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_special_representatives' AND nested_links.link_type IN ('person', 'role'))
                   OR (links.link_type = 'ordered_traffic_commissioners' AND nested_links.link_type IN ('person', 'role')))
          LIMIT 1
        )
       FROM "links" INNER JOIN "link_sets" ON "link_sets"."id" = "links"."link_set_id" WHERE "link_sets"."content_id" = $1 AND 1=1 ORDER BY "links"."link_type" ASC, "links"."position" ASC  [["content_id", "f9fcf3fe-2751-4dca-97ca-becaeceb4b26"]]

  SELECT "links"."link_type", "links"."target_content_id", "documents"."locale", "editions"."id"
  FROM "links"
  LEFT OUTER JOIN "editions" ON "editions"."id" = "links"."edition_id"
  LEFT OUTER JOIN "documents" ON "documents"."id" = "editions"."document_id"
  WHERE "documents"."content_id" = :content_id
    AND "documents"."locale" = :locale
    AND "editions"."content_store" = :content_store
  ORDER BY "links"."link_type" ASC, "links"."position" ASC


