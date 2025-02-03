-- Ensure that wal_level is set to logical in pgconfig

-- Create a new publication
CREATE PUBLICATION graphql_pub FOR
TABLE editions WHERE (state <> 'superseded'),
TABLE documents,
TABLE links,
TABLE link_sets,
TABLE unpublishings,
TABLE change_notes,
TABLE access_limits;

-- Create a replication slot, so that we don't get a deadlock when creating a subscriber in the same cluster
SELECT * FROM pg_create_logical_replication_slot('graphql_pub_slot', 'pgoutput');
