FROM ruby:2.7.2-buster

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled
ENV RACK_ENV=production
ENV LANG=en_US.UTF-8

EXPOSE 3000

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql postgresql-contrib openssl sudo
RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt-get update -qq && apt-get install -y yarn nodejs
RUN cd /app
WORKDIR /app
RUN node --version

COPY . /app

RUN gem install bundler && gem install rails && bundle install && yarn

CMD ["bash", "docker-entrypoint.sh"]
