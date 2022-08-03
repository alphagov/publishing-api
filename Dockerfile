ARG base_image=ghcr.io/alphagov/govuk-ruby-base:3.1.2
ARG builder_image=ghcr.io/alphagov/govuk-ruby-builder:3.1.2

FROM $builder_image AS builder

RUN install_packages libpq-dev

ENV GOVUK_APP_NAME=publishing-api
RUN mkdir /app
WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version /app/
RUN bundle install
COPY . /app

FROM $base_image

RUN install_packages curl libpq-dev

# TODO: DATABASE_URL shouldn't be set here but seems to be required by E2E tests, figure out why.
ENV DATABASE_URL=postgresql://postgres@postgres/publishing-api PORT=3093
ENV GOVUK_CONTENT_SCHEMAS_PATH=/govuk-content-schemas
ENV GOVUK_APP_NAME=publishing-api
ENV RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672 RABBITMQ_EXCHANGE=published_documents

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/
COPY --from=builder /app /app/
WORKDIR /app
CMD bundle exec puma
