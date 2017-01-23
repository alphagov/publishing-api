# Needed to work around the fact that we use a polymorphic type and to avoid
# including a migration which changed the class name in the database, we simply
# make sure it is available under both names
Edition = ContentItem
