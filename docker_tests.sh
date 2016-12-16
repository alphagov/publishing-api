#! /bin/bash
set -x

docker build -t publishing-api:dev .

DB_CONTAINER=$(docker run -d --name db postgres:9.3)
trap 'docker rm -f ${DB_CONTAINER}' EXIT

docker_run() {
  docker run \
    --link db \
    -v ${PWD}:/app \
    -v ${PWD/%publishing-api/govuk-content-schemas}:/tmp/govuk-content-schemas \
    -e GOVUK_CONTENT_SCHEMAS_PATH=/tmp/govuk-content-schemas \
    -e RAILS_ENV=test \
    -e DATABASE_URL=postgresql://postgres@db/publishing_api_development \
    -e VIRTUAL_HOST=publishing-api.dev.gov.uk \
    publishing-api:dev \
    $@
}

docker_run bin/rails db:create db:environment:set db:schema:load
docker_run bin/rspec
