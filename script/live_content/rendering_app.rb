puts Edition.live.where(base_path: ARGV).pick(:rendering_app)
