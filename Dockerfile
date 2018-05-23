FROM ruby:2.3.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev
RUN curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get update -qq && apt-get install -y yarn nodejs
RUN mkdir -p /app
WORKDIR /app
RUN node --version
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN ["bundle", "install"]
COPY package.json /app/package.json
RUN ["yarn"]
COPY . /app/
CMD ["rails", "s"]