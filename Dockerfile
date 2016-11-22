FROM ruby:2.3.1
RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y build-essential libpq-dev libxml2-dev libxslt1-dev && apt-get clean

# for capybara-webkit
RUN apt-get install -y libqt4-webkit libqt4-dev xvfb

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN bundle install
ADD . $APP_HOME
