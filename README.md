# Phoenix

Phoenix is a web app to submit points to the Terms of Service; Didn't Read project.

## Development

The app was developed with Ruby on Rails. The database uses PostgreSQL. You must have those if you want to run the app.

Please refer to the [QUICKSTART.md](./QUICKSTART.md) guide for more information. If anything is missing, please let us know.

## Database

All the details on the database schema can be found on the [wiki](https://github.com/tosdr/edit.tosdr.org/wiki/database).

## Export

Careful! The postgres database dumps produced during this process contain user accounts that should
be kept secret. Never commit a database dump to git, or share it with someone who does not also have
access to our Heroku account!

```sh
# make sure you have edit.tosdr.org checked out next to tosdr.org in a folder:
git clone https://github.com/tosdr/edit.tosdr.org
git clone https://github.com/tosdr/tosdr.org
mkdir tosdr.org/src/pointsPhoenix
cd edit.tosdr.org
sh ./db/deploy.sh
```

## API

All the details on the API can be found on the [wiki](https://github.com/tosdr/edit.tosdr.org/wiki/api)

## Core developers
* [Chris](https://github.com/piks3l/)
* [Jesse](https://github.com/JesseWeinstein)
* [Madeline](https://github.com/madoleary)
* [Michiel](https://github.com/michielbdejong)
* [Vincent](https://github.com/vinnl)

### Hosting
* https://edit.tosdr.org (production) - Michiel's Heroku (other core developers have access too)


## License

AGPL-3.0+ (GNU Affero General Public License, version 3 or later)

