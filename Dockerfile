FROM ruby:2.7-alpine

ENV DRY_RUN=false
ENV CI_API_V4_URL=https://gitlab.com/api/v4
ENV PATH="/usr/src/app/bin:${PATH}"

RUN apk add --no-cache bash

WORKDIR /usr/src/app

ADD ./Gemfile ./Gemfile.lock ./

RUN bundle config set without 'development test' \
    && bundle install

ADD . .

RUN mkdir /usr/src/data 
WORKDIR /usr/src/data

CMD ["ggm"]
