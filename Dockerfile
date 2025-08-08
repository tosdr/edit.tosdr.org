FROM ruby:3.0.6-slim-bullseye as base

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=enabled
ENV RAILS_LOG_TO_STDOUT=enabled
ENV LANG=en_US.UTF-8
ENV PYTHON=/usr/bin/python3

ARG GIT_TAG=nightly

WORKDIR /usr/src/edit.tosdr.org

# Install system dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential libpq-dev postgresql postgresql-contrib openssl sudo \
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libxkbcommon0 \
  libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
  curl gnupg python3 python3-distutils

# Add Yarn & Node.js repos
RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    curl -sL https://deb.nodesource.com/setup_16.x | bash -

# Install Node and Yarn
RUN apt-get update -qq && apt-get install -y yarn nodejs && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Install bundler
RUN gem install bundler -v 2.4.14

# -----------------------
# Caching layer: only updates when deps change
# -----------------------
COPY Gemfile Gemfile.lock ./
RUN bundle config set force_ruby_platform true
RUN bundle install --jobs 4 --retry 3

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

# -----------------------
# Copy app code after deps
# -----------------------
COPY . .

# -----------------------
# Build targets
# -----------------------

FROM base as dev
CMD ["bash", "docker-entrypoint.sh"]

FROM base as prod
RUN bundle install --without development test --jobs 4 --retry 3
CMD ["bash", "docker-entrypoint.sh"]