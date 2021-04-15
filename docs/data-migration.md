# Writing data migrations

## Are you writing a migration to change Publishing API data?

We have a lot of migrations added to the Publishing API to change data, our
long term plan is to reduce these so that these can be done via the API itself
and not need migrations. Until we are at that point please use the following
guidelines when creating migrations.

### Run the migration on your machine first

At the very least this will ensure that the code runs and that your data looks
correct, but it also allows you to get an idea for how long the migration will
take to finish. You should then include that information in the PR to help with
whoever is doing the deployment.

We also encourage you to run and check the results of the migration on
integration, since the data there will be closer to production.

### Always include the `schema.rb` file

Even if the change is just the timestamp, it's important to include this file
in your commit otherwise when trying to use the app in testing an error saying
there are pending migrations will appear.

### Target only content related to the application you are affecting

Mistakes in migrations can and do happen, by at least targeting the application
you are affecting (with `.where(publishing_app: )`) you can avoid unnecessary
fallout.

### Don't assume the records you are altering exist

Migrations get run in test environments, on old databases or when a developer
first clones the project. You should always make sure that your migrations run
fine without the data there that you are expecting.

### Do you need to represent this data downstream?

Representing the data downstream won't work on local machines, so you will need
to have a check in the migration making sure it is running in the right
environment (`Rails.env.production?`). Alternatively, and ideally, you can
[use the `represent_downstream:` class of rake tasks][rake-tasks] in Jenkins to
achieve the same result. If you do decide to represent downstream in the
migration itself, you must disable transactions for this migration (by running
the `disable_ddl_transaction!` method) as otherwise you will be representing
downstream before the data is committed to the database.

### If you are disabling the transaction, ensure the migration is idempotent

If you have `disable_ddl_transaction!` in your migration for some reason, you
should make sure that the migration will do the right thing if it gets run
again. This could happen if it happens to fail the first time, but since it
will not be running in a transaction, the data won't be rolled back.

[rake-tasks]: lib/tasks/represent_downstream.rake
