select * from expansion_rule_steps where link_type = 'taxons';

select distinct state from editions;

-- How to find a link expansion rule by path?
-- TODO test this
-- TODO build this query with active record / Arel?
with recursive
  arg(path) as (select array['parent', 'parent', 'parent']::text[]),
  next_steps as (
    select
      rel.expansion_rule_id as expansion_rule_id,
      child_step.id as child_step_id,
      child_step.link_type,
      path[2:] as remaining_path
    from expansion_rule_steps step
    join arg on path[1] = link_type
    join expansion_rule_step_relationships rel
      on step.id = rel.child_step_id
      and rel.parent_step_id is null
    join expansion_rule_step_relationships child_rel
      on child_rel.parent_step_id = rel.child_step_id
      and child_rel.expansion_rule_id = rel.expansion_rule_id
    join expansion_rule_steps child_step
      on child_rel.child_step_id = child_step.id

    union

    select
      child_rel.expansion_rule_id as expansion_rule_id,
      child_step.id as child_step_id,
      child_step.link_type,
      remaining_path[2:] as remaining_path
    from next_steps
    join expansion_rule_step_relationships child_rel
      on child_rel.parent_step_id = next_steps.child_step_id
      and child_rel.expansion_rule_id = next_steps.expansion_rule_id
    join expansion_rule_steps child_step
      on child_rel.child_step_id = child_step.id
    where next_steps.link_type = remaining_path[1]
  )
  select distinct link_type
  from next_steps
  where cardinality(remaining_path) = 0;

analyze;

explain analyze with recursive
  root_links_by_link_type(note, content_id, link_type, content_id_path, link_type_path, is_cycle) as
  (
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
      join expansion_reverse_rules on links.link_type = expansion_reverse_rules.link_type
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
      join expansion_reverse_rules on links.link_type = expansion_reverse_rules.link_type
      where links.target_content_id = :content_id
      and documents.locale = :locale
      and editions.content_store = :content_store
  ),
  child_links_by_link_type(depth, note, content_id, link_type, content_id_path, link_type_path, is_cycle) as (
    with recursive
      next_link_types(content_id, expansion_rule_id, child_step_id, link_type, remaining_path) as (
        select
          root_links_by_link_type.content_id,
          rel.expansion_rule_id as expansion_rule_id,
          child_step.id as child_step_id,
          child_step.link_type,
          root_links_by_link_type.link_type_path[2:] as remaining_path
        from expansion_rule_steps step
        join root_links_by_link_type on link_type_path[1] = step.link_type
        join expansion_rule_step_relationships rel
          on step.id = rel.child_step_id
          and rel.parent_step_id is null
        join expansion_rule_step_relationships child_rel
          on child_rel.parent_step_id = rel.child_step_id
          and child_rel.expansion_rule_id = rel.expansion_rule_id
        join expansion_rule_steps child_step
          on child_rel.child_step_id = child_step.id

        union

        select
          next_link_types.content_id,
          child_rel.expansion_rule_id as expansion_rule_id,
          child_step.id as child_step_id,
          child_step.link_type,
          remaining_path[2:] as remaining_path
        from next_link_types
        join expansion_rule_step_relationships child_rel
          on child_rel.parent_step_id = next_link_types.child_step_id
          and child_rel.expansion_rule_id = next_link_types.expansion_rule_id
        join expansion_rule_steps child_step
          on child_rel.child_step_id = child_step.id
        where next_link_types.link_type = remaining_path[1]
      ),
      next_reverse_link_types(content_id, next_link_type, next_link_name) as (
        select
          next_link_types.content_id,
          expansion_reverse_rules.link_type,
          expansion_reverse_rules.name
        from next_link_types
        join expansion_reverse_rules on next_link_types.link_type = expansion_reverse_rules.name
      ),
      base_case(depth, note, content_id, link_type, content_id_path, link_type_path, is_cycle) as
    (
    -- Forward Link Set Links
    select
      1 as depth,
      'forward link set links' as note,
      links.target_content_id,
      next_link_types.link_type,
      root_links_by_link_type.content_id_path || links.target_content_id,
      root_links_by_link_type.link_type_path || next_link_types.link_type,
      links.target_content_id = ANY(root_links_by_link_type.content_id_path)
    from root_links_by_link_type
    join next_link_types
      on next_link_types.content_id = root_links_by_link_type.content_id
    join links on links.link_type = next_link_types.link_type
    join link_sets on links.link_set_id = link_sets.id
      and link_sets.content_id = next_link_types.content_id
  union
  -- Forward Edition Links
    select
      1 as depth,
      'forward edition links' as note,
      links.target_content_id,
      next_link_types.link_type,
      root_links_by_link_type.content_id_path || links.target_content_id,
      root_links_by_link_type.link_type_path || next_link_types.link_type,
      links.target_content_id = ANY(root_links_by_link_type.content_id_path)
    from root_links_by_link_type
    join next_link_types
      on next_link_types.content_id = root_links_by_link_type.content_id
    join documents on documents.content_id = next_link_types.content_id
    join editions on documents.id = editions.document_id
    join links on editions.id = links.edition_id and links.link_type = next_link_types.link_type
    where documents.locale = :locale and editions.content_store = :content_store
  union
    -- Reverse Link Set Links
      select
        1 as depth,
        'reverse link set links' as note,
        link_sets.content_id,
        next_reverse_link_types.next_link_name,
        root_links_by_link_type.content_id_path || link_sets.content_id,
        root_links_by_link_type.link_type_path || next_reverse_link_types.next_link_name,
        link_sets.content_id = ANY(root_links_by_link_type.content_id_path)
      from root_links_by_link_type
      join next_reverse_link_types
        on next_reverse_link_types.content_id = root_links_by_link_type.content_id
      join links on links.link_type = next_reverse_link_types.next_link_type
        and links.target_content_id = next_reverse_link_types.content_id
      join link_sets on links.link_set_id = link_sets.id
    union
      -- Reverse Edition Links
      select
        1 as depth,
        'reverse edition links' as note,
        documents.content_id,
        next_reverse_link_types.next_link_name,
        root_links_by_link_type.content_id_path || documents.content_id,
        root_links_by_link_type.link_type_path || next_reverse_link_types.next_link_name,
        documents.content_id = ANY(root_links_by_link_type.content_id_path)
      from root_links_by_link_type
      join next_reverse_link_types
        on next_reverse_link_types.content_id = root_links_by_link_type.content_id
      join links on links.link_type = next_reverse_link_types.next_link_type
        and links.target_content_id = next_reverse_link_types.content_id
      join editions on links.edition_id = editions.id
      join documents on editions.document_id = documents.id
      where documents.locale = :locale and editions.content_store = :content_store
    )
    select depth, note, content_id, link_type, content_id_path, link_type_path, is_cycle
    from base_case
    union
    (
      with recursive recursive_links_by_link_type as (
        select depth, note, content_id, link_type, content_id_path, link_type_path, is_cycle from child_links_by_link_type
        where is_cycle = false
      ),
      next_link_types(content_id, expansion_rule_id, child_step_id, link_type, remaining_path) as (
        select
          recursive_links_by_link_type.content_id,
          rel.expansion_rule_id as expansion_rule_id,
          child_step.id as child_step_id,
          child_step.link_type,
          recursive_links_by_link_type.link_type_path[2:] as remaining_path
        from expansion_rule_steps step
        join recursive_links_by_link_type on link_type_path[1] = step.link_type
        join expansion_rule_step_relationships rel
          on step.id = rel.child_step_id
          and rel.parent_step_id is null
        join expansion_rule_step_relationships child_rel
          on child_rel.parent_step_id = rel.child_step_id
          and child_rel.expansion_rule_id = rel.expansion_rule_id
        join expansion_rule_steps child_step
          on child_rel.child_step_id = child_step.id

        union

        select
          next_link_types.content_id,
          child_rel.expansion_rule_id as expansion_rule_id,
          child_step.id as child_step_id,
          child_step.link_type,
          remaining_path[2:] as remaining_path
        from next_link_types
        join expansion_rule_step_relationships child_rel
          on child_rel.parent_step_id = next_link_types.child_step_id
          and child_rel.expansion_rule_id = next_link_types.expansion_rule_id
        join expansion_rule_steps child_step
          on child_rel.child_step_id = child_step.id
        where next_link_types.link_type = remaining_path[1]
      ),
      next_reverse_link_types(content_id, next_link_type, next_link_name) as (
        select
          next_link_types.content_id,
          expansion_reverse_rules.link_type,
          expansion_reverse_rules.name
        from next_link_types
        join expansion_reverse_rules on next_link_types.link_type = expansion_reverse_rules.name
      )
      -- Forward Link Set Links
      select
        recursive_links_by_link_type.depth + 1,
        'forward link set links' as note,
        links.target_content_id,
        next_link_types.link_type,
        recursive_links_by_link_type.content_id_path || links.target_content_id,
        recursive_links_by_link_type.link_type_path || next_link_types.link_type,
        links.target_content_id = ANY(recursive_links_by_link_type.content_id_path)
      from recursive_links_by_link_type
      join next_link_types
        on next_link_types.content_id = recursive_links_by_link_type.content_id
      join links on links.link_type = next_link_types.link_type
      join link_sets on links.link_set_id = link_sets.id
        and link_sets.content_id = next_link_types.content_id
    union
    -- Forward Edition Links
      select
        recursive_links_by_link_type.depth + 1,
        'forward edition links' as note,
        links.target_content_id,
        next_link_types.link_type,
        recursive_links_by_link_type.content_id_path || links.target_content_id,
        recursive_links_by_link_type.link_type_path || next_link_types.link_type,
        links.target_content_id = ANY(recursive_links_by_link_type.content_id_path)
      from recursive_links_by_link_type
      join next_link_types
        on next_link_types.content_id = recursive_links_by_link_type.content_id
      join documents on documents.content_id = next_link_types.content_id
      join editions on documents.id = editions.document_id
      join links on editions.id = links.edition_id and links.link_type = next_link_types.link_type
      where documents.locale = :locale and editions.content_store = :content_store
    union
      -- Reverse Link Set Links
        select
          recursive_links_by_link_type.depth + 1,
          'reverse link set links' as note,
          link_sets.content_id,
          next_reverse_link_types.next_link_name,
          recursive_links_by_link_type.content_id_path || link_sets.content_id,
          recursive_links_by_link_type.link_type_path || next_reverse_link_types.next_link_name,
          link_sets.content_id = ANY(recursive_links_by_link_type.content_id_path)
        from recursive_links_by_link_type
        join next_reverse_link_types
          on next_reverse_link_types.content_id = recursive_links_by_link_type.content_id
        join links on links.link_type = next_reverse_link_types.next_link_type
          and links.target_content_id = next_reverse_link_types.content_id
        join link_sets on links.link_set_id = link_sets.id
      union
        -- Reverse Edition Links
        select
          recursive_links_by_link_type.depth + 1,
          'reverse edition links' as note,
          documents.content_id,
          next_reverse_link_types.next_link_name,
          recursive_links_by_link_type.content_id_path || documents.content_id,
          recursive_links_by_link_type.link_type_path || next_reverse_link_types.next_link_name,
          documents.content_id = ANY(recursive_links_by_link_type.content_id_path)
        from recursive_links_by_link_type
        join next_reverse_link_types
          on next_reverse_link_types.content_id = recursive_links_by_link_type.content_id
        join links on links.link_type = next_reverse_link_types.next_link_type
          and links.target_content_id = next_reverse_link_types.content_id
        join editions on links.edition_id = editions.id
        join documents on editions.document_id = documents.id
        where documents.locale = :locale and editions.content_store = :content_store
    )
)
select 0 as depth, note, link_type_path, content_id, content_id_path, is_cycle from root_links_by_link_type
union
select depth, note, link_type_path, content_id, content_id_path, is_cycle from child_links_by_link_type
order by depth desc;
