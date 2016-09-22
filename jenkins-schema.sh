#!/bin/bash

export REPO_NAME="alphagov/govuk-content-schemas"
export CONTEXT_MESSAGE="Verify publishing-api against content schemas"

exec ./jenkins.sh
