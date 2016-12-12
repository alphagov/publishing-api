#!/bin/bash

export PACT_BROKER_BASE_URL=https://pact-broker.dev.publishing.service.gov.uk

# Cleanup anything left from previous test runs
git clean -fdx

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment --without development

bundle exec govuk-lint-ruby \
  --format html --out rubocop-${GIT_COMMIT}.html \
  --format clang \
  app config Gemfile lib spec

bin/rails db:environment:set
bundle exec rake db:drop db:create db:schema:load

# Clone govuk-content-schemas depedency for contract tests
rm -rf /tmp/govuk-content-schemas
git clone git@github.com:alphagov/govuk-content-schemas.git /tmp/govuk-content-schemas
(
 cd /tmp/govuk-content-schemas
 git checkout ${SCHEMA_GIT_COMMIT:-"deployed-to-production"}
)
export GOVUK_CONTENT_SCHEMAS_PATH=/tmp/govuk-content-schemas

export RCOV=1
if bundle exec rake ${TEST_TASK:-"default"}; then
  if [ -n "$PACT_TARGET_BRANCH" ]; then
    bundle exec rake pact:publish:branch
  fi
else
  exit 1
fi
