FROM ruby:2.7.2-buster

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled
ENV LANG=en_US.UTF-8
ENV WEB_HOST localhost
ENV WEB_PORT 9090

ARG GIT_TAG=nightly

WORKDIR /usr/src/edit.tosdr.org

COPY . .
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql postgresql-contrib openssl sudo && \
    curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update -qq && apt-get install -y yarn nodejs && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    yarn

RUN gem install bundler -v 2.2.6
COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install --jobs 4 --retry 3

CMD ["bash", "docker-entrypoint.sh"]
