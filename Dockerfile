ARG base_image=ruby:2.7.2
FROM ${base_image}
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev && apt-get clean
RUN gem install foreman

# This image is only intended to be able to run this app in a production RAILS_ENV
ENV RAILS_ENV production

ENV DATABASE_URL postgresql://postgres@postgres/publishing-api
ENV GOVUK_APP_NAME publishing-api
ENV GOVUK_CONTENT_SCHEMAS_PATH /govuk-content-schemas
ENV PORT 3093
ENV RABBITMQ_URL amqp://guest:guest@rabbitmq:5672
ENV RABBITMQ_EXCHANGE published_documents

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle config set deployment 'true'
RUN bundle config set without 'development test'
RUN bundle install --jobs 4
ADD . $APP_HOME

CMD foreman run web
