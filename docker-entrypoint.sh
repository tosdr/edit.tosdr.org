#!/bin/bash

set -m

if [ ! -f /etc/SECRET_KEY_BASE ]; then
	echo $(openssl rand -hex 128) > /etc/SECRET_KEY_BASE
fi

export SECRET_KEY_BASE=$(cat /etc/SECRET_KEY_BASE)

rails db:migrate

rake tmp:clear
rake assets:precompile

if [ -v INIT_SETUP ]; then
	rails db:seed
fi

bundle exec puma -C config/puma.rb

bundle exec rails s -b 0.0.0.0 -p $WEB_PORT

exec "$@"