-- First load the schema using rails db:setup:graphql_logical_replica

CREATE SUBSCRIPTION graphql_sub
CONNECTION 'dbname=publishing_api_development'
PUBLICATION graphql_pub
WITH (create_slot = false, slot_name = 'graphql_pub_slot');