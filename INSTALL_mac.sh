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
echo '[*] Installing Rbenv'

if [ -d ~/.rbenv ]; then
  echo 'Rbenv exists installing Ruby 3.4.9, it might take a while...'
  rbenv install 3.4.9
else
  brew install rbenv
  echo 'Rbenv exists now installing Ruby 3.4.9, it might take a while...'
  rbenv install 3.4.9
fi

if hash yarn 2>/dev/null; then
  echo 'You have yarn!'
else
  brew install yarn
fi

if hash psql 2>/dev/null; then
  echo 'You have postgres!'
else
  echo '[*] Installing postgres'
  brew install postgres
  brew services start postgresql
fi

echo '[*] Setting local ruby version to 3.4.9'
rbenv local 3.4.9
echo '[*] Installing gems'
bundle install
echo '[*] Compiling JS'
yarn install
echo '[*] Setting up the database'
rails db:create db:migrate

echo '[*] You are ready to go! Run "rails server" to start the server'
