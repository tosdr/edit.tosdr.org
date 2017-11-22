# Phoenix

![Heroku](https://heroku-badge.herokuapp.com/?app=tosdr-phoenix)

Phoenix is a web app to submit points to the Terms of Service; Didn't Read project. The template used is located [here](https://github.com/lewagon/rails-templates)

## Requierements

The app was developped with Ruby on Rails 5.1.4 and Ruby 2.3.5. The database uses PostgreSQL. You must have those if you want to run the app.

Use github version or [rbenv](https://github.com/rbenv/rbenv) to manage your ruby version.

## Install

```
git clone git@github.com:tosdr/phoenix.git
cd phoenix
bundle install
rails db:create db:migrate
rails s
```
No test/development seeds are available for the moment.

## Database

All the details on the database schema can be found on the [wiki](https://github.com/tosdr/wiki/database).


## API

All the details on the API can be found on the [wiki](https://github.com/tosdr/phoenix/wiki/api)

## License

AGPL-3.0+ (GNU Affero General Public License, version 3 or later)

