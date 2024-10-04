# Decision Record: Add new event type to add custom dependency resolution behaviour when a Content Block is updated

## Context

### Existing behaviour

The way content blocks are handled leans on a lot of existing functionality within the publishing platform. 
Previously to the introduction of content blocks, documents had (and still have!) the concept of “links”, so when a 
document is changed, this triggers the republication of all the documents that are associated with that page.

A good example of this is an “Organisation” page (for example, the Cabinet Office). The Cabinet Office organisation 
page, as well as listing some information about the organisation, also lists the ministers for that organisation.

When the frontend fetches the organisation from the content store, it also gets the ministers (stored as links). 
This information is static within the content store, so if information about those ministers changes, we need to 
send the organisation page back to the Content Store along with the new minister information.

This is done through a process known as dependency resolution. When we publish a minister, we get all that 
minister’s dependent documents, and resend them to the content store as shown:

https://gist.github.com/pezholio/3b698953ec84b569a90df331e0b7c559

### Content Block requirements

With content blocks, this process remains largely unchanged, when a block is changed, we fetch the dependent 
documents and send them to the content stores. As part of the process of sending the documents to the content stores,
we perform a find/replace to find the embed code and replace it with the actual content of the blocks.

Going forward, we’d like to do a couple of things:

1. If a member of the public is signed up to receive email alerts on a dependent document, we’d like to alert them 
   when content is changed as a result of a content block within that document changing; and
2. Add a change note in publishing apps to inform the editors and the public that the document(s) have been 
   republished as a result of a change to a content block

For email alerts, there is already a mechanism to add a `major` event type to the RabbitMQ queue when a document is 
published and the change is a major change. This then gets picked up by the Email Alerts Service, which then 
triggers email notifications for subscribed users.

We have looked into hooking into this behaviour to “fake” a `major` event message to then trigger email alerts when 
a dependent document is updated. This has a couple of issues:

1. The code is already quite verbose, and this adds a bunch of complexities
2. We need to reach into the payload and generate a new changenote for each dependent bit of content, which causes 
   misdirection and is again, quite messy

## Decisions

We therefore suggest updating the Publishing API code to:
1. receive a new `content_block` update type 
2. when this update type is used, call a new Sidekiq Job to update host documents with a new `host_content` update type

In the near future we will then be able to add Change Notes to the relevant Host Documents, and update the Email Alerts 
Service to subscribe to the `host_content` event.

## Consequences

We believe that this will make the intent of the code clearer, as well as allow us to make changes in an incremental way.

This will also enable two way communication between publishing apps, allowing users to see at a glance when content 
blocks have triggered a change.

The work to implement Change Notes will require some changes to the publishing apps themselves, as 
well as potentially some duplication of code in each app. However, this is a good practical illustration of why we 
are trying to reduce the number of publishing apps in the estate.

We could trial this with Whitehall at first, and then expand to Mainstream, Travel Advice etc if the ideal proves 
successful.


