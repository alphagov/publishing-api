puts Edition.live.where(base_path: ARGV.fetch(0)).first.rendering_app
