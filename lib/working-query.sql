explain analyze with
  root_links_by_link_type(subquery, content_id, link_type) as
  (
    with reverse_link_types(link_type, reverse_link_name) AS (
      select distinct revs.link_type, revs.name from link_expansion_rules lers
      join link_expansion_rule_relationships rels on lers.id = rels.link_expansion_rule_id
      join link_expansion_reverse_rules revs on lers.link_type = revs.name
      where rels.parent_id is null
    )
    -- Forward Link Set Links
      select 'forward link set links' as subquery, target_content_id, links.link_type
      from links
      join link_sets on links.link_set_id = link_sets.id
      where link_sets.content_id = :content_id
    union
    -- Forward Edition Links
      select 'forward edition links' as subquery, links.target_content_id, links.link_type
      from links
      join editions on links.edition_id = editions.id
      join documents on editions.document_id = documents.id
      where documents.content_id = :content_id
      and documents.locale = :locale
      and editions.content_store = :content_store
    union
    -- Reverse Link Set Links
      select 'reverse link set links' as subquery, link_sets.content_id, links.link_type
      from links
      join link_sets on links.link_set_id = link_sets.id
      join reverse_link_types on links.link_type = reverse_link_types.link_type
      where links.target_content_id = :content_id
    union
    -- Reverse Edition Links
      select 'reverse edition links' as subquery, documents.content_id, links.link_type
      from links
      join editions on editions.id = links.edition_id
      join documents on editions.document_id = documents.id
      join reverse_link_types on links.link_type = reverse_link_types.link_type
      where links.target_content_id = :content_id
      and documents.locale = :locale
      and editions.content_store = :content_store
  ),
  child_links_by_link_type(subquery, content_id, link_type) as (
    with link_types(content_id, link_type, link_expansion_rule_id) as (
      select root_links_by_link_type.content_id, children.link_type, rels.id from root_links_by_link_type
      join link_expansion_rules rules on rules.link_type = root_links_by_link_type.link_type
      join link_expansion_rule_relationships rels on rules.id = rels.parent_id
      join link_expansion_rules children on children.id = rels.link_expansion_rule_id
    ),
    reverse_link_types(content_id, link_type, reverse_link_name, link_expansion_rule_id) as (
      select root_links_by_link_type.content_id, revs.link_type, revs.name, rels.id from root_links_by_link_type
      join link_expansion_rules rules on rules.link_type = root_links_by_link_type.link_type
      join link_expansion_rule_relationships rels on rules.id = rels.parent_id
      join link_expansion_rules children on children.id = rels.link_expansion_rule_id
      join link_expansion_reverse_rules revs on children.link_type = revs.name
    )
    -- Forward Link Set Links
    -- TODO path as a separate column
      select 'forward link set links' as subquery, target_content_id, links.link_type
      from link_types
      join links on links.link_type = link_types.link_type
      join link_sets on links.link_set_id = link_sets.id
        and link_sets.content_id = link_types.content_id
    union
    -- Forward Edition Links
      select 'forward edition links' as subquery, links.target_content_id, links.link_type
      from link_types
      join documents on documents.content_id = link_types.content_id
      join editions on documents.id = editions.document_id
      join links on editions.id = links.edition_id and links.link_type = link_types.link_type
      where documents.locale = :locale and editions.content_store = :content_store
    union
    -- Reverse Link Set Links
      select 'reverse link set links' as subquery, link_sets.content_id, reverse_link_name
      from reverse_link_types
      join links on links.link_type = reverse_link_types.link_type
        and links.target_content_id = reverse_link_types.content_id
      join link_sets on links.link_set_id = link_sets.id
    union
    -- Reverse Edition Links
    select 'reverse edition links' as subquery, documents.content_id, reverse_link_name
    from reverse_link_types
    join links on links.link_type = reverse_link_types.link_type
      and links.target_content_id = reverse_link_types.content_id
    join editions on links.edition_id = editions.id
    join documents on editions.document_id = documents.id
    where documents.locale = :locale and editions.content_store = :content_store
    -- Debugging
    -- union
    -- select 'debug link types: ' || link_expansion_rule_id, content_id, link_type from link_types
    -- union
    -- select 'debug reverse link types: ' || reverse_link_name, content_id, link_type from reverse_link_types
)
select 0 as depth, subquery, content_id, link_type from root_links_by_link_type
union all
select 1 as depth, subquery, content_id, link_type from child_links_by_link_type
order by depth desc;


-- How to find a link expansion rule by path?
with recursive
path(path) as (select array['role_appointments', 'role']),
link_types(link_type, path) as (
  select distinct children.link_type, path.path[2:] from link_expansion_rules ler
  join path on ler.link_type = path.path[1]
  join link_expansion_rule_relationships rels on ler.id = rels.parent_id
  join link_expansion_rules children on children.id = rels.link_expansion_rule_id
  union
  select children.link_type, link_types.path[2:] from link_expansion_rules ler
  join link_types on ler.link_type = link_types.link_type and ler.link_type = link_types.path[1]
  join link_expansion_rule_relationships rels on ler.id = rels.parent_id
  join link_expansion_rules children on children.id = rels.link_expansion_rule_id
)
select link_type from link_types where cardinality(link_types.path) = 0