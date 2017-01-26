# These are monkey patches to work around us changing one of our model classes
# from ContentItem to Edition.
#
# These are required because on LockVersion these are stored as a polymorphic
# association and thus the class is stored in the database. These monkey patches
# change the logic so that the database still stores a "ContentItem" string
# and loads Edition objects

ActiveRecord::Associations::BelongsToPolymorphicAssociation.class_eval do
  # When we load up an polymorphic association we will switch the type to be
  # Edition when it is an instance of ContentItem
  def klass
    type = owner[reflection.foreign_type]
    type = "Edition" if type == "ContentItem"
    type.presence && type.constantize
  end


  # When saving a record we will replace the name of the target to be
  # ContentItem if it is set to be Edition, this allows us to roll back.
  alias_method :original_replace_keys, :replace_keys

  def replace_keys(record)
    original_replace_keys(record)
    owner[reflection.foreign_type] = "ContentItem" if owner[reflection.foreign_type] == "Edition"
  end
end

ActiveRecord::PredicateBuilder::AssociationQueryHandler.class_eval do
  # This is a patch to have query scopes convert a find for a type of Edition
  # to actually search for a type of "ContentItem"
  def call(_, value)
    queries = {}

    table = value.associated_table
    if value.base_class
      class_name = value.base_class == Edition ? "ContentItem" : value.base_class.name
      queries[table.association_foreign_type.to_s] = class_name
    end

    queries[table.association_foreign_key.to_s] = value.ids
    predicate_builder.build_from_hash(queries)
  end
end
