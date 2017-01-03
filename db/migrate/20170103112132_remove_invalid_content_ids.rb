class RemoveInvalidContentIds < ActiveRecord::Migration[5.0]
  def up
    execute "do $$
             DECLARE
               rec record;
             BEGIN
               FOR rec IN
                 SELECT * FROM events
               LOOP
                 BEGIN
                 PERFORM rec.content_id::uuid;
                 EXCEPTION WHEN invalid_text_representation THEN
                   DELETE FROM events WHERE content_id = rec.content_id;
                 END;
               END LOOP;
             END;
           $$;"

    execute "do $$
             DECLARE
               rec record;
             BEGIN
               FOR rec IN
                 SELECT * FROM links
               LOOP
                 BEGIN
                 PERFORM rec.target_content_id::uuid;
                 EXCEPTION WHEN invalid_text_representation THEN
                   DELETE FROM links WHERE target_content_id = rec.target_content_id;
                 END;
               END LOOP;
             END;
           $$;"

    execute "do $$
             DECLARE
               rec record;
             BEGIN
               FOR rec IN
                 SELECT * FROM link_sets
               LOOP
                 BEGIN
                 PERFORM rec.content_id::uuid;
                 EXCEPTION WHEN invalid_text_representation THEN
                   DELETE FROM links WHERE link_set_id = (SELECT id FROM link_sets WHERE content_id = rec.content_id);
                   DELETE FROM link_sets WHERE content_id = rec.content_id;
                 END;
               END LOOP;
             END;
           $$;"
  end
end
