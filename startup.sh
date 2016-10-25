#!/bin/bash

export GOVUK_CONTENT_SCHEMAS_PATH=${GOVUK_CONTENT_SCHEMAS_PATH:-'../govuk-content-schemas/dist'}
bundle install
bundle exec rails server -p 3093
