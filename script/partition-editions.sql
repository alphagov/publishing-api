-- An SQL script to partition the 'editions' table so that
-- superseded editions are in their own partition.
--
-- This is experimental, to be run on a developer's device.

-- Create a new table "peditions" (partitioned editions)
DROP TABLE IF EXISTS public.peditions;

CREATE TABLE public.peditions (
    id integer DEFAULT nextval('public.editions_id_seq'::regclass) NOT NULL,
    title text,
    public_updated_at timestamp without time zone,
    publishing_app character varying,
    rendering_app character varying,
    update_type character varying,
    phase character varying DEFAULT 'live'::character varying,
    analytics_identifier character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    document_type character varying,
    schema_name character varying,
    first_published_at timestamp without time zone,
    last_edited_at timestamp without time zone,
    state character varying NOT NULL,
    user_facing_version integer DEFAULT 1 NOT NULL,
    base_path text,
    content_store character varying,
    document_id integer NOT NULL,
    description text,
    publishing_request_id character varying,
    major_published_at timestamp without time zone,
    published_at timestamp without time zone,
    publishing_api_first_published_at timestamp without time zone,
    publishing_api_last_edited_at timestamp without time zone,
    auth_bypass_ids character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    details jsonb DEFAULT '{}'::jsonb,
    routes jsonb DEFAULT '[]'::jsonb,
    redirects jsonb DEFAULT '[]'::jsonb,
    last_edited_by_editor_id uuid
) PARTITION BY LIST (state);

-- Create a partition for each non-superseded state.
-- It isn't possible to define this as VALUES NOT IN ('superseded')
CREATE TABLE pedition_other
PARTITION OF peditions
FOR VALUES IN ('draft', 'published', 'unpublished');

-- Create a partition for 'superseded' editions
CREATE TABLE pedition_superseded
PARTITION OF peditions
FOR VALUES IN ('superseded');

ALTER TABLE public.peditions OWNER TO postgres;

-- Drop foreign key constraints from tables that relate to 'editions',
-- otherwise deleting from 'editions' will either fail or will cascadingly
-- delete rows from these tables.
ALTER TABLE ONLY public.links DROP CONSTRAINT fk_rails_1cd48ea4e4;
ALTER TABLE ONLY public.change_notes DROP CONSTRAINT fk_rails_2ce6b0e165;
ALTER TABLE ONLY public.unpublishings DROP CONSTRAINT fk_rails_7a351881fd;
ALTER TABLE ONLY public.peditions DROP CONSTRAINT fk_rails_c88f919482;
ALTER TABLE ONLY public.peditions DROP CONSTRAINT peditions_pkey;

-- Move rows from 'editions' to 'peditions' in batches
CREATE OR REPLACE PROCEDURE batch_move_data(batch_size INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    rows_moved INTEGER;
BEGIN LOOP
        WITH deleted_rows AS (
            DELETE FROM editions
            WHERE id IN (
                SELECT id
                FROM editions
                ORDER BY id
                LIMIT batch_size
                FOR UPDATE SKIP LOCKED
            )
            RETURNING * )
        INSERT INTO peditions
        SELECT * FROM deleted_rows;

        GET DIAGNOSTICS rows_moved = ROW_COUNT;

        COMMIT;

        EXIT WHEN rows_moved = 0;

    END LOOP;
END;
$$;

CALL batch_move_data(1000);

-- Recreate foreign key constraints
ALTER TABLE ONLY public.links
    ADD CONSTRAINT fk_rails_1cd48ea4e4 FOREIGN KEY (edition_id) REFERENCES public.peditions(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.change_notes
    ADD CONSTRAINT fk_rails_2ce6b0e165 FOREIGN KEY (edition_id) REFERENCES public.peditions(id);
ALTER TABLE ONLY public.unpublishings
    ADD CONSTRAINT fk_rails_7a351881fd FOREIGN KEY (edition_id) REFERENCES public.peditions(id) ON DELETE CASCADE;
ALTER TABLE ONLY public.peditions
    ADD CONSTRAINT fk_rails_c88f919482 FOREIGN KEY (document_id) REFERENCES public.documents(id);
ALTER TABLE ONLY public.peditions
    ADD CONSTRAINT peditions_pkey PRIMARY KEY (state, id);

-- Index the peditions table
CREATE UNIQUE INDEX peditions_base_path_content_store_idx ON public.peditions USING btree (state, base_path, content_store);
CREATE UNIQUE INDEX peditions_document_id_content_store_idx ON public.peditions USING btree (state, document_id, content_store);
CREATE INDEX peditions_document_id_document_type_idx ON public.peditions USING btree (document_id, document_type) WHERE ((details ->> 'current'::text) = 'true'::text);
CREATE INDEX peditions_document_id_document_type_idx1 ON public.peditions USING btree (document_id, document_type) WHERE ((content_store)::text = 'live'::text);
CREATE INDEX peditions_document_id_id_idx ON public.peditions USING btree (document_id, id);
CREATE INDEX peditions_document_id_idx ON public.peditions USING btree (document_id);
CREATE UNIQUE INDEX peditions_document_id_user_facing_version_idx ON public.peditions USING btree (state, document_id, user_facing_version);
CREATE INDEX peditions_document_type_state_idx ON public.peditions USING btree (document_type, state);
CREATE INDEX peditions_document_type_updated_at_idx ON public.peditions USING btree (document_type, updated_at);
CREATE INDEX peditions_id_content_store_idx ON public.peditions USING btree (id, content_store);
CREATE INDEX peditions_publishing_app_idx ON public.peditions USING btree (publishing_app);
CREATE INDEX peditions_redirects_idx ON public.peditions USING gin (redirects jsonb_path_ops);
CREATE INDEX peditions_routes_idx ON public.peditions USING gin (routes jsonb_path_ops);
CREATE INDEX peditions_state_base_path_idx ON public.peditions USING btree (base_path);
CREATE INDEX peditions_updated_at_id_idx ON public.peditions USING btree (updated_at, id);
CREATE INDEX peditions_updated_at_idx ON public.peditions USING btree (updated_at);

-- Replace the editions table with the peditions table
DROP TABLE editions;
ALTER TABLE peditions RENAME TO editions;
