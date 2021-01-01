FROM ruby:2.7-alpine

ENV DRY_RUN=false
ENV CI_API_V4_URL=https://gitlab.com/api/v4
ENV GGM_CONFIG_FILE=.ggm.yaml

RUN apk add --no-cache bash

WORKDIR /usr/src/app

ADD ./Gemfile ./Gemfile.lock ./

RUN bundle config set without 'development test' \
    && bundle install

ADD . .

ENV DRY_RUN=false
CMD ["bin/ggm.rb"]
