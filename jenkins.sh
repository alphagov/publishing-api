#!/bin/bash

REPO_NAME=${REPO_NAME:-"alphagov/publishing-api"}
CONTEXT_MESSAGE=${CONTEXT_MESSAGE:-"default"}
GH_STATUS_GIT_COMMIT=${SCHEMA_GIT_COMMIT:-${GIT_COMMIT}}

function github_status {
  REPO_NAME="$1"
  STATUS="$2"
  MESSAGE="$3"
  gh-status "$REPO_NAME" "$GH_STATUS_GIT_COMMIT" "$STATUS" -d "Build #${BUILD_NUMBER} ${MESSAGE}" -u "$BUILD_URL" -c "$CONTEXT_MESSAGE" >/dev/null
}

function error_handler {
  trap - ERR # disable error trap to avoid recursion
  local parent_lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "$message" ]] ; then
    echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
  else
    echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
  fi
  github_status "$REPO_NAME" error "errored on Jenkins"
  exit "${code}"
}

trap 'error_handler ${LINENO}' ERR
github_status "$REPO_NAME" pending "is running on Jenkins"

# Cleanup anything left from previous test runs
git clean -fdx

# Try to merge master into the current branch, and abort if it doesn't exit
# cleanly (ie there are conflicts). This will be a noop if the current branch
# is master.
git merge --no-commit origin/master || git merge --abort

export RAILS_ENV=test
bundle install --path "${HOME}/bundles/${JOB_NAME}" --deployment --without development

# Uncomment if this app uses a database
bundle exec rake db:drop db:create db:schema:load db:test:prepare

if bundle exec rake ${TEST_TASK:-"default"}; then
  github_status "$REPO_NAME" success "succeeded on Jenkins"
else
  github_status "$REPO_NAME" failure "failed on Jenkins"
  exit 1
fi
