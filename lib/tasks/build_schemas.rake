desc "regenerate schemas and validate"
task build_schemas: %i[
  regenerate_schemas
  validate_dist_schemas
  validate_uniqueness_of_frontend_example_base_paths
  validate_links
  format_examples
  validate_examples
]
