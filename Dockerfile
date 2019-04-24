FROM ruby:2.6.3
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev && apt-get clean
RUN gem install foreman

ENV DATABASE_URL postgresql://postgres@postgres/publishing-api
ENV GOVUK_APP_NAME publishing-api
ENV GOVUK_CONTENT_SCHEMAS_PATH /govuk-content-schemas
ENV PORT 3093
ENV RABBITMQ_URL amqp://guest:guest@rabbitmq:5672
ENV RABBITMQ_EXCHANGE published_documents
ENV RAILS_ENV development
ENV REDIS_HOST redis
ENV TEST_DATABASE_URL postgresql://postgres@postgres/publishing-api-test

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME

CMD foreman run web
