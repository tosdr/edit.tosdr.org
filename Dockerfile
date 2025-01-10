FROM ruby:3.1.2 as base

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled
ENV LANG=en_US.UTF-8

ARG GIT_TAG=nightly

WORKDIR /usr/src/edit.tosdr.org

COPY . .
RUN apt-get update -qq && apt-get install -y build-essential libxml2-dev libxslt1-dev zlib1g-dev libpq-dev postgresql postgresql-contrib openssl sudo && \
    curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update -qq && apt-get install -y yarn nodejs && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    yarn

RUN gem install bundler -v 2.4.14
RUN bundle config set force_ruby_platform true
COPY Gemfile Gemfile.lock ./

FROM base as dev
RUN bundle check || bundle install
CMD ["bash", "docker-entrypoint.sh"]

FROM base as prod
RUN bundle check || bundle install --without development test --jobs 4 --retry 3
CMD ["bash", "docker-entrypoint.sh"]
