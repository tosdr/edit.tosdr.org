#!/bin/bash

set -m

# SECRET_KEY_BASE signs session and Devise remember-me cookies, so it must stay
# the same across deploys. Set it in the environment (e.g. the Portainer stack).
# The fallback below lives inside the container and is lost on every redeploy.
if [ -z "$SECRET_KEY_BASE" ]; then
	echo "WARNING: SECRET_KEY_BASE is not set; using a container-local random key. Users will be logged out on every redeploy." >&2
	if [ ! -f /etc/SECRET_KEY_BASE ]; then
		echo $(openssl rand -hex 128) > /etc/SECRET_KEY_BASE
	fi
	export SECRET_KEY_BASE=$(cat /etc/SECRET_KEY_BASE)
fi

rails db:migrate

rake tmp:clear

if [ -v INIT_SETUP ]; then
	bundle exec rake db:seed
fi

# Starting the Rails server
# Option 1: Using puma
exec bundle exec puma -C config/puma.rb

# Option 2: Using rails server
# exec bundle exec rails s -b 0.0.0.0 -p $WEB_PORT

exec "$@"