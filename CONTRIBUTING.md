# Contributing

To contribution, you need to set up the dev environment, nothing too hard. 

## Install Ruby with [Rbenv](https://github.com/rbenv/rbenv)

(shamelessly copied from Rbenv doc)

### Basic GitHub Checkout

This will get you going with the latest version of rbenv without needing
a systemwide install.

1. Clone rbenv into `~/.rbenv`.

    ~~~ sh
    $ git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    ~~~

    Optionally, try to compile dynamic bash extension to speed up rbenv. Don't
    worry if it fails; rbenv will still work normally:

    ~~~
    $ cd ~/.rbenv && src/configure && make -C src
    ~~~

2. Add `~/.rbenv/bin` to your `$PATH` for access to the `rbenv`
   command-line utility.

    ~~~ sh
    $ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
    ~~~

    **Ubuntu Desktop note**: Modify your `~/.bashrc` instead of `~/.bash_profile`.

    **Zsh note**: Modify your `~/.zshrc` file instead of `~/.bash_profile`.

3. Run `~/.rbenv/bin/rbenv init` and follow the instructions to set up
   rbenv integration with your shell. This is the step that will make
   running `ruby` "see" the Ruby version that you choose with rbenv.

4. Restart your shell so that PATH changes take effect. (Opening a new
   terminal tab will usually do it.)

5. Verify that rbenv is properly set up using this
   [rbenv-doctor](https://github.com/rbenv/rbenv-installer/blob/master/bin/rbenv-doctor) script:

    ~~~ sh
    $ curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
    Checking for `rbenv' in PATH: /usr/local/bin/rbenv
    Checking for rbenv shims in PATH: OK
    Checking `rbenv install' support: /usr/local/bin/rbenv-install (ruby-build 20170523)
    Counting installed Ruby versions: none
      There aren't any Ruby versions installed under `~/.rbenv/versions'.
      You can install Ruby versions like so: rbenv install 2.2.4
    Checking RubyGems settings: OK
    Auditing installed plugins: OK
    ~~~

6. _(Optional)_ Install [ruby-build][], which provides the
   `rbenv install` command that simplifies the process of
   [installing new Ruby versions](#installing-ruby-versions).

## When it's done

In your code directory:

    ~~~ sh
    git clone https://github.com/tosdr/phoenix
    cd phoenix
    rbenv local 2.3.5
    bundle install
    rails db:seed
    rails s
    ~~~
    
And you're ready to code !

## Committing & Pull Requests

    * If it's a fix use [fix] as a prefix of your message, if it's an enhancement, use [enh]. 
    * When you create a pull request, please make sure you checked everything in the PR template. 
    
Have fun!
