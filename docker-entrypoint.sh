#!/bin/bash

set -m

echo "=== Checking Node availability ==="
which node
ruby -e "p File.executable? '/usr/bin/node'"
node --version
echo "=== Node check complete ==="

if [ ! -f /etc/SECRET_KEY_BASE ]; then
	echo $(openssl rand -hex 128) > /etc/SECRET_KEY_BASE
fi

export SECRET_KEY_BASE=$(cat /etc/SECRET_KEY_BASE)

export EXECJS_RUNTIME=Node
export PATH="/usr/bin/:$PATH"
bundle exec rake db:migrate

rake tmp:clear

if [ -v INIT_SETUP ]; then
	bundle exec rake db:seed
fi

# Start cron in the background
service cron start
whenever --update-crontab

# Starting the Rails server
# Option 1: Using puma
exec bundle exec puma -C config/puma.rb

# Option 2: Using rails server
# exec bundle exec rails s -b 0.0.0.0 -p $WEB_PORT

exec "$@"