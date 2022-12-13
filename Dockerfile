FROM ruby:2.7.2-buster

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled
ENV RACK_ENV=production
ENV LANG=en_US.UTF-8

EXPOSE 3000


COPY . /app
WORKDIR /app

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql postgresql-contrib openssl sudo && \
    curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
    apt-get update -qq && apt-get install -y yarn nodejs && \
    cd /app && \
    gem install bundler && gem install rails && bundle install && yarn

CMD ["bash", "docker-entrypoint.sh"]
