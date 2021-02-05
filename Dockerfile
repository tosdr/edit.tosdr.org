FROM ruby:2.7.2-buster

ENV RAILS_ENV=docker
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
RUN mkdir -p /app
WORKDIR /app
RUN node --version

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

# Run the rest of the commands as the ``postgres``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf

USER root

RUN ["gem", "install", "bundler"]
RUN ["bundle", "install"]
COPY package.json /app/package.json
RUN ["yarn"]
COPY . /app/
CMD ["bash", "docker-entrypoint.sh"]