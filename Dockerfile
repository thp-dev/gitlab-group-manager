FROM ruby:2.7-alpine

RUN apk add --no-cache bash

WORKDIR /usr/src/app

ADD ./Gemfile ./Gemfile.lock ./

RUN bundle config set without 'development test' \
    && bundle install

ADD . .

ENV DRY_RUN=false
CMD ["bin/ggm.rb"]
