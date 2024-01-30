-- TODO - if we can get away with only using this view, then we've massively overcomplicated the link_expansion_rule tables
create or replace temporary view lers as (
  select child.link_type as child_link_type, coalesce(parent.link_type, 'root') as parent_link_type
  from link_expansion_rule_relationships rels
  join link_expansion_rules child on child.id = rels.link_expansion_rule_id
  left join link_expansion_rules parent on parent.id = rels.parent_id
);
select * from lers;

-- How to find a link expansion rule by path?
with recursive
  arg(path) as (select array['taxons', 'parent_taxons', 'parent_taxons']::text[]),
  next_link_types(link_type, path) as (
    select distinct child_link_type, arg.path from arg
    join lers on child_link_type = path[1] and parent_link_type = 'root'
    union
    select child_link_type, next_link_types.path[2:] from lers
    join next_link_types on lers.parent_link_type = next_link_types.link_type
    and lers.parent_link_type = next_link_types.path[1]
  )
  select link_type from next_link_types where cardinality(next_link_types.path) = 0;

explain analyze with
  root_links_by_link_type(note, content_id, link_type, content_id_path, link_type_path, is_cycle) as
  (
    with reverse_link_types(link_type, reverse_link_name) AS (
      select distinct revs.link_type, revs.name from lers
      join link_expansion_reverse_rules revs on lers.child_link_type = revs.name
      where lers.parent_link_type is null
    )
    -- Forward Link Set Links
      select
        'forward link set links' as note,
        links.target_content_id,
        links.link_type,
        array[links.target_content_id],
        array[links.link_type],
        false
      from links
      join link_sets on links.link_set_id = link_sets.id
      where link_sets.content_id = :content_id
    union
    -- Forward Edition Links
      select
        'forward edition links' as note,
        links.target_content_id,
        links.link_type,
        array[links.target_content_id],
        array[links.link_type],
        false
      from links
      join editions on links.edition_id = editions.id
      join documents on editions.document_id = documents.id
      where documents.content_id = :content_id
      and documents.locale = :locale
      and editions.content_store = :content_store
    union
    -- Reverse Link Set Links
      select
        'reverse link set links' as note,
        link_sets.content_id,
        links.link_type,
        array[link_sets.content_id],
        array[links.link_type],
        false
      from links
      join link_sets on links.link_set_id = link_sets.id
      join reverse_link_types on links.link_type = reverse_link_types.link_type
      where links.target_content_id = :content_id
    union
    -- Reverse Edition Links
      select
        'reverse edition links' as note,
        documents.content_id,
        links.link_type,
        array[documents.content_id],
        array[links.link_type],
        false
      from links
      join editions on editions.id = links.edition_id
      join documents on editions.document_id = documents.id
      join reverse_link_types on links.link_type = reverse_link_types.link_type
      where links.target_content_id = :content_id
      and documents.locale = :locale
      and editions.content_store = :content_store
  ),
  child_links_by_link_type(note, content_id, link_type, content_id_path, link_type_path, is_cycle) as (
    with recursive next_link_types(content_id, original_link_type, next_link_type, link_type_path) as (
        select
          root_links_by_link_type.content_id,
          root_links_by_link_type.link_type,
          child_link_type,
          link_type_path
        from root_links_by_link_type
        join lers on child_link_type = root_links_by_link_type.link_type_path[1] and parent_link_type = 'root'
      union
        select
          next_link_types.content_id,
          next_link_types.original_link_type,
          child_link_type,
          link_type_path[2:]
        from next_link_types
        join lers on lers.parent_link_type = next_link_types.next_link_type
        and lers.parent_link_type = next_link_types.link_type_path[1]
      ),
      next_reverse_link_types(content_id, original_link_type, next_link_type, next_link_name) as (
        select
          next_link_types.content_id,
          next_link_types.original_link_type,
          link_expansion_reverse_rules.link_type,
          link_expansion_reverse_rules.name
        from next_link_types
        join link_expansion_reverse_rules on link_expansion_reverse_rules.name = next_link_types.next_link_type
        where cardinality(link_type_path) = 0
      )
  --  select
  --    'debug: next_link_types',
  --    root_links_by_link_type.content_id,
  --    next_link_type,
  --    root_links_by_link_type.content_id_path || root_links_by_link_type.content_id, -- TODO
  --    root_links_by_link_type.link_type_path || next_link_type,
  --    root_links_by_link_type.content_id = ANY(root_links_by_link_type.content_id_path) -- TODO
  --  from root_links_by_link_type
  --  join next_link_types
  --    on next_link_types.content_id = root_links_by_link_type.content_id
  --    and next_link_types.original_link_type = root_links_by_link_type.link_type
  --    and cardinality(next_link_types.link_type_path) = 0
  --union
  --  select
  --    'debug: reverse_next_link_types',
  --    root_links_by_link_type.content_id,
  --    next_link_type,
  --    root_links_by_link_type.content_id_path || root_links_by_link_type.content_id, -- TODO
  --    root_links_by_link_type.link_type_path || next_link_type,
  --    root_links_by_link_type.content_id = ANY(root_links_by_link_type.content_id_path) -- TODO
  --  from root_links_by_link_type
  --  join next_reverse_link_types
  --    on next_reverse_link_types.content_id = root_links_by_link_type.content_id
  --    and next_reverse_link_types.original_link_type = root_links_by_link_type.link_type
  --union
    -- Forward Link Set Links
    select
      'forward link set links' as note,
      links.target_content_id,
      next_link_types.next_link_type,
      root_links_by_link_type.content_id_path || links.target_content_id,
      root_links_by_link_type.link_type_path || next_link_types.next_link_type,
      links.target_content_id = ANY(root_links_by_link_type.content_id_path)
    from root_links_by_link_type
    join next_link_types
      on next_link_types.content_id = root_links_by_link_type.content_id
      and next_link_types.original_link_type = root_links_by_link_type.link_type
    join links on links.link_type = next_link_types.next_link_type
    join link_sets on links.link_set_id = link_sets.id
      and link_sets.content_id = next_link_types.content_id
  union
  -- Forward Edition Links
    select
      'forward edition links' as note,
      links.target_content_id,
      next_link_types.next_link_type,
      root_links_by_link_type.content_id_path || links.target_content_id,
      root_links_by_link_type.link_type_path || next_link_types.next_link_type,
      links.target_content_id = ANY(root_links_by_link_type.content_id_path)
    from root_links_by_link_type
    join next_link_types
      on next_link_types.content_id = root_links_by_link_type.content_id
      and next_link_types.original_link_type = root_links_by_link_type.link_type
    join documents on documents.content_id = next_link_types.content_id
    join editions on documents.id = editions.document_id
    join links on editions.id = links.edition_id and links.link_type = next_link_types.next_link_type
    where documents.locale = :locale and editions.content_store = :content_store
    -- union
    -- -- Reverse Link Set Links
    --   select 'reverse link set links' as note, array[link_sets.content_id], array[reverse_link_name]
    --   from reverse_link_types
    --   join links on links.link_type = reverse_link_types.link_type
    --     and links.target_content_id = reverse_link_types.content_id
    --   join link_sets on links.link_set_id = link_sets.id
    -- union
    -- -- Reverse Edition Links
    -- select 'reverse edition links' as note, array[documents.content_id], array[reverse_link_name]
    -- from reverse_link_types
    -- join links on links.link_type = reverse_link_types.link_type
    --   and links.target_content_id = reverse_link_types.content_id
    -- join editions on links.edition_id = editions.id
    -- join documents on editions.document_id = documents.id
    -- where documents.locale = :locale and editions.content_store = :content_store
    -- -- Debugging
    -- -- union
    -- -- select 'debug link types: ' || link_expansion_rule_id, content_id, link_type from link_types
    -- -- union
    -- -- select 'debug reverse link types: ' || reverse_link_name, content_id, link_type from reverse_link_types
)
select 0 as depth, note, link_type_path, content_id_path, is_cycle from root_links_by_link_type
union all
select 1 as depth, note, link_type_path, content_id_path, is_cycle from child_links_by_link_type
order by depth desc;
