# (unless we decide to use Bitnami instead)
ARG base_image=ruby:2.7.5-slim-buster

FROM $base_image AS builder
# TODO: have a separate build image which already contains the build-only deps.
RUN apt-get update -qy && apt-get upgrade -y
# TODO: Look to remove Node v9 (below) (E2E tests currently fail without it).
RUN curl -sL https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get update && apt-get install -y build-essential nodejs git npm libpq-dev && \
    npm install -g phantomjs-prebuilt@2 --unsafe-perm
ENV RAILS_ENV=production GOVUK_APP_NAME=publishing-api
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle config set force_ruby_platform true
RUN bundle install --jobs=8 --retry=2
COPY . /app

FROM $base_image
RUN apt-get update -qy && apt-get upgrade -y && \
    apt-get install -y nodejs libpq-dev
# TODO: DATABASE_URL shouldn't be set here but seems to be required by E2E tests, figure out why.
ENV DATABASE_URL=postgresql://postgres@postgres/publishing-api PORT=3093
ENV GOVUK_CONTENT_SCHEMAS_PATH=/govuk-content-schemas
ENV RAILS_ENV=production GOVUK_APP_NAME=publishing-api
ENV RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672 RABBITMQ_EXCHANGE=published_documents

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/
WORKDIR /app
CMD bundle exec puma
