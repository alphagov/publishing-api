#!/bin/bash

set -e

export PACT_BROKER_BASE_URL=https://pact-broker.dev.publishing.service.gov.uk
export GOVUK_CONTENT_SCHEMAS_PATH=/tmp/govuk-content-schemas
export RAILS_ENV=test
export RCOV=1

# Cleanup anything left from previous test runs
git clean -fdx

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment --without development

bundle exec govuk-lint-ruby app config Gemfile lib spec

bin/rails db:environment:set
bundle exec rake db:drop db:create db:schema:load

# Clone govuk-content-schemas depedency for contract tests
rm -rf $GOVUK_CONTENT_SCHEMAS_PATH
git clone git@github.com:alphagov/govuk-content-schemas.git $GOVUK_CONTENT_SCHEMAS_PATH
(
 cd $GOVUK_CONTENT_SCHEMAS_PATH
 git checkout ${SCHEMA_GIT_COMMIT:-"deployed-to-production"}
)

bundle exec rake ${TEST_TASK:-"default"}

if [ -n "$PACT_TARGET_BRANCH" ]; then
  bundle exec rake pact:publish:branch
fi
