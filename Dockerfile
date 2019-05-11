FROM ruby:2.3.5

ENV RAILS_ENV=production \
    RUBY_GLOBAL_METHOD_CACHE_SIZE=131072 \
    RUBY_GC_HEAP_GROWTH_MAX_SLOTS=40000 \
    RUBY_GC_HEAP_INIT_SLOTS=400000 \
    RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5 \
    RUBY_GC_MALLOC_LIMIT=90000000

# Temp fix, remove it when you use a newer version of supported Docker ruby image 
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

# Install yarn
RUN apt-get update \
&&  apt-get install -y curl apt-transport-https \
&&  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
&&  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
&&  curl --silent --location https://deb.nodesource.com/setup_8.x | bash - \
&&  apt-get update && apt-get install -y \
      nodejs\
      yarn \
&&  apt-get autoremove -y \
&&  rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN addgroup --gid 1000 app \
&&  adduser --system --uid 1000 --ingroup app --shell /bin/bash app \
&& chown -R app:app /app
USER app

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN ["bundle", "install"]

COPY package.json package.json
RUN ["yarn"]

COPY . .
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
