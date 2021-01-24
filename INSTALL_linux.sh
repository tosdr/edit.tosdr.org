#/bin/bash

echo ''
echo '[*] Welcome to the installer for edit.tosdr.org!'
echo ''
echo '  ###############'
echo '  ###############'
echo '  ###########          I have read and agreed to the terms'
echo '  ###########          is the biggest lie on the web.'
echo '  #######'
echo '  #######              We aim to fix that.'

sleep 1;
echo ''
export PATH="$HOME/.rbenv/bin:$PATH"
if [ -d ~/.rbenv/plugins/ruby-build ]; then
  echo 'You have Rbenv!'
else
  echo '[*] Installing Rbenv'
  export PATH="$HOME/.rbenv/shims:$PATH"
  curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
  echo "Setting up rbenv in your shell..."
fi
eval "$(rbenv init -)"

if rbenv versions --bare | grep -q 2.7.2 ; then
  echo "You have Ruby 2.7.2!"
else
  echo '[*] Installing Ruby 2.7.2, it might take a while...'
  rbenv install 2.7.2
fi

if hash yarn 2>/dev/null; then
  echo 'You have yarn!'
else
  echo '[*] Installing yarn'
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update && sudo apt-get -y install yarn
fi

if hash psql 2>/dev/null; then
  echo 'You have postgres!'
else
  echo '[*] Installing postgres'
  sudo apt-get install -y postgresql postgresql-contrib libpq-dev build-essential
  # TODO: find a way to setup postgres for the user
  #echo `whoami` > /tmp/caller
  #sudo su - postgres
  #psql --command "CREATE ROLE `cat /tmp/caller` LOGIN createdb;"
  #exit
  #rm -f /tmp/caller
fi
if command -v phantomjs > /dev/null ; then
  echo 'You have phantomjs!'
else
  echo '[*] Installing phantomjs'
  sudo apt-get -y install phantomjs
fi
echo '[*] Setting local ruby version to 2.7.2'
rbenv local 2.7.2
if rbenv which bundle 2&>1 > /dev/null ; then
  echo 'You have bundler!'
else
  echo '[*] Installing budler'
  gem install bundler
fi
echo '[*] Installing gems'
bundle install
echo '[*] Compiling JS'
yarn install
echo '[*] Setting up the database'
rails db:create db:migrate

echo '[*] You are ready to go! Run "rails server" to start the server'
