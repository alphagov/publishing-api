# Deleting Documents, Editions and Links

To delete content from the Publishing API you will need to create a [data
migration][data-migration].

If you need to delete all traces of a document from the system:

```ruby
require_relative "helpers/delete_content"

class RemoveYourDocument < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContent.destroy_documents_with_links("some-content-id")
  end
end
```

If you need to delete a single edition:

```ruby
require_relative "helpers/delete_content"

class RemoveYourEdition < ActiveRecord::Migration
  def up
    editions = Edition.where(id: 123)

    Helpers::DeleteContent.destroy_supporting_objects(editions)

    editions.destroy_all
  end
end
```

If you need to delete just the links for a document:

```ruby
require_relative "helpers/delete_content"

class RemoveLinks < ActiveRecord::Migration
  # Remove /some/base-path
  def up
    Helpers::DeleteContent.destroy_links("some-content-id")
  end
end
```

[data-migration]: https://github.com/alphagov/publishing-api/blob/master/CONTRIBUTING.md#are-you-writing-a-migration-to-change-publishing-api-data
