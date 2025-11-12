SELECT "editions".* FROM (
    SELECT
        editions.*,
        "links"."target_content_id" AS "target_content_id",
        "links"."link_type" AS "link_type",
        "links"."edition_id" AS "edition_id",
        "links"."position" AS "position",
        "links"."id" AS "link_id",
        "documents"."content_id",
        "documents"."locale",
        row_number() OVER (
            PARTITION BY
                "documents"."content_id",
                "links"."link_type",
                "links"."target_content_id"
            ORDER BY (
                CASE
                    WHEN ("documents"."locale" = :primary_locale) THEN 0
                    ELSE 1
                END
            )
        )
    FROM "editions"
    INNER JOIN "documents" ON "documents"."id" = "editions"."document_id"
    INNER JOIN links ON links.link_set_content_id = documents.content_id
    WHERE
        "editions"."content_store" = :content_store
        AND "documents"."locale" IN (:locale_with_fallback)
        AND "editions"."document_type" NOT IN (:non_renderable_formats)
        AND (
            ("links"."target_content_id", "links"."link_type") IN (
                :content_id_tuples
            )
        )
        AND (
            "links"."link_type" IN (
                :unpublished_link_types
            )
            OR "editions"."state" != 'unpublished'
        )
    UNION
    SELECT
        editions.*,
        "links"."target_content_id" AS "target_content_id",
        "links"."link_type" AS "link_type",
        "links"."edition_id" AS "edition_id",
        "links"."position" AS "position",
        "links"."id" AS "link_id",
        "documents"."content_id",
        "documents"."locale",
        row_number() OVER (
            PARTITION BY
                "documents"."content_id",
                "links"."link_type",
                "links"."target_content_id"
            ORDER BY (
                CASE
                    WHEN ("documents"."locale" = :primary_locale) THEN 0
                    ELSE 1
                END
            )
        )
    FROM "editions"
    INNER JOIN "documents" ON "documents"."id" = "editions"."document_id"
    INNER JOIN "links" ON "links"."edition_id" = "editions"."id"
    WHERE
        "editions"."content_store" = :content_store
        AND "documents"."locale" IN (:locale_with_fallback)
        AND "editions"."document_type" NOT IN (:non_renderable_formats)
        AND (
            ("links"."target_content_id", "links"."link_type") IN (
                :content_id_tuples
            )
        )
        AND (
            "links"."link_type" IN (
                :unpublished_link_types
            )
            OR "editions"."state" != 'unpublished'
        )
) AS editions
WHERE "editions"."row_number" = 1
ORDER BY
    "link_type" ASC, "position" ASC, "link_id" DESC
