# Phoenix

## Table of COntents

- [Overview](#overview)
  - [Infrastructure](#infrastructure)
- [Development](#development)
  - [Running Phoenix](#running-phoenix)
    - [With Docker](#with-docker)
    - [With Hypothesis](#with-hypothesis)
- [Database](#database)
- [API](#api)
- [License](#license)

---

## Overview

Feel free to skip ahead to [**Development**](https://github.com/tosdr/edit.tosdr.org#development), if you're more interested in technical implementation.

Phoenix is a web application to submit *points* to the Terms of Service; Didn't Read (ToS;DR) project.
Think of a _point_ as a succinct, easy-to-understand mini-conclusion sourced from the complex text
of either Privacy Policy or Terms of Service agreements.
For example, [_You can retrieve an archive of your data_](https://edit.tosdr.org/points/32363), or
[_Your personal data is used for automated decision-making, profiling or AI training_](https://edit.tosdr.org/points/33639).

Points are used by ToS;DR to analyse Privacy Policies and Terms of Service agreements across the web,
then grading online services based on their respect for users' privacy and personal data.
By services, we mean websites and web applications. Think YouTube, or Amazon.

The heart of Phoenix lies in user-submitted points (thanks to our awesome community),
which are reviewed for accuracy and approved by our dedicated team of curators.
Users submit points by annotating a service's documents, e.g. Privacy Policy,
which Phoenix obtains and stores through web-scraping.

Once a service has been comprehensively analysed in Phoenix, as determined by our curators,
the grades appear on [tosdr.org](https://tosdr.org).

An **A** grade indicates that the service treats users with a high level of respect
for their privacy and personal data. Grades **D** and **E** indicate that the services treat users
without much respect for their privacy and personal data. Examples include [GitHub](https://tosdr.org/en/service/297) and [Facebook](https://tosdr.org/en/service/182).

The grades are calculated based on an algorithm, which, in our case is really just a simple list of
conditions that factor in the balance of any given service's points, the relationship of the points
to each other, and certain thresholds. This algorithm is subject to change.
You can read more about it on our [forum](https://tosdr.community/).
We discuss how it has changed here: [_Updating the algorithm for service grades – thoughts?_](https://tosdr.community/t/updating-the-algorithm-for-service-grades-thoughts/2926/1)

### Infrastructure

Phoenix is a Ruby on Rails application with some Vue.js mixed in, using a PostgreSQL database.

For annotation, Phoenix relies on a customised instance of [Hypothesis](https://github.com/hypothesis),
including both forks of the [Hypothesis web application repository](https://github.com/tosdr/h) and the [Hypothesis client](https://github.com/tosdr/client).

This is a _new implementation_, [merged](https://github.com/tosdr/edit.tosdr.org/pull/1116) for use in production on May 17, 2023.
That being said, **it is still experimental**.

When used, Phoenix also connects to two other services: Atlassian, which runs both our [widget](https://status.tosdr.org) (helps us to monitor the application's health),
and `jrbit.de` (where our databases live as well as our system for reporting errors).

---

## Development

**Requirements**:

We rely on Docker as an attempt to be OS-agnostic.

- [Docker](https://docs.docker.com/engine/install/) and `docker-compose`

**If you are not able to use Docker**, you'll need to have the following dependencies installed:

- Ruby 3.4.9
- Rails (Phoenix uses version 7.1.x)
- Bundler 2.4.14
- Postgres 15
- Node.js (to access Yarn)

Please refer to the [Quickstart Guide](./QUICKSTART.md) for more information on manual set-up.
If anything is either missing or out of date, please let us know.

There are two ways to run Phoenix in development: with or without Hypothesis.
Plenty of hacking around can be done without running Hypothesis, particularly if you just want to
get your feet wet or see what the codebase is all about.

**If you are not interested in running Hypothesis, please skip ahead to [Running Phoenix](#running-phoenix)**.

**NOTE: The use of Hypothesis within Phoenix is not supported without Docker**

### Running Phoenix

First of all, clone Phoenix using Git and enter the cloned directory:

```sh
git clone --recurse-submodules https://git.tosdr.org/tosdr/phoenix.git
cd phoenix
```

The following steps should be completed from the root of the cloned repository.

#### With Docker

If you have installed [`docker-compose`](https://docs.docker.com/compose/install/), getting the application running
involves five configuration commands, after which it can be started with a single command in the future.

To prepare the application, run the following commands to build the application and initialise the database:

```sh
docker-compose build
docker network create elasticsearch
docker network create dbs
docker-compose up
docker exec -it edittosdrorg_web_1 rails db:seed
```

**NOTE**: We use docker networks to facilitate development with Hypothesis. Hypothesis and Phoenix
share a database, as well as an Elasticsearch instance:

- The `dbs` network is the shared database.
- The `elasticsearch` network is the shared Elasticsearch instance.

From then on, you can start the application by running:

```sh
docker-compose up
```

If you add or remove dependencies (e.g. Ruby Gems), add the following arguments:

```sh
docker-compose up --build --remove-orphans
```

Here's an explanation of what each step does:

1. `docker-compose up`

This will launch the following services:

- The Phoenix web application
- The database (`postgres:11.5-alpine`)
- `Elasticsearch` (needed to run Hypothesis)
- `adminer` (for inspecting the database)

The Phoenix web application runs on port 9090 (http://localhost:9090).

If you wish simply to run the web application and the database, you can launch these services
on their own by running:

```sh
docker-compose up web db
```

- To debug application code using `byebug`, open a new terminal tab and attach to the running
  web application container:
  ```sh
  docker attach phoenix-web-1 # Or however the web container is named
  ```

- While we are in the process of developing our test coverage, our test environment also runs
  in Docker and relies on [rspec-rails](https://github.com/rspec/rspec-rails); you can launch tests
  by running:
  ```sh
  docker-compose -f docker-compose.yml -f docker-compose.test.yml run --rm web bundle exec rspec
  ```

- To access the Rails console, run:
  ```sh
  docker-compose run web rails c
  ```

2. **Create your user via the sign-up page, or use one of the seeded users**.

_**This will only work if you have seeded the database.**_

There are three seeded users: `tosdr_admin`, `tosdr_curator`, `tosdr_user`.
You can log in with any one of the following email addresses (password is `Justforseed1`):

- admin@selfhosted.tosdr.org - Admin account
- curator@selfhosted.tosdr.org - Curator account
- user@selfhosted.tosdr.org - User account

3. If you create your own user, confirm it manually.

First you'll need to access the Rails console:

```sh
docker-compose run web rails c
```

Find, then confirm your user:

```
> user = User.find_by_username('your_username')
> user.confirm
```

4. Sign-in.

5. To debug the database, try the following command:

```sh
docker exec -it db psql -U postgres
```

Due to a bug in the seeds you will currently need to run:

```sql
insert into document_types values (0, 'terms of service', now(), now(), null, 1, 'approved');
```

To **annotate** a service, navigate to the services page from the top-right menu, choose a service,
and click `View Documents`.
Begin by highlighting a piece of text from this page (**both `H` and the Hypothesis client must be running**).

For a demonstration of how annotations work, feel free to inspect the video attached to
[this PR](https://github.com/tosdr/edit.tosdr.org/pull/1116).

#### With Hypothesis

**Part 1:**

`H` is the Hypothesis web service and API. To use it with Phoenix, clone our
[fork of `H`](https://github.com/tosdr/h) in the same directory as the Phoenix clone,
then change directory into the `H` repository.

**The correct branch to work from is the *phoenix-integration* branch.**

```sh
git clone --recurse-submodules https://github.com/tosdr/h.git ./h
cd h
```

**ATTENTION**: The official documentation for installing `H` can be found [here](https://h.readthedocs.io/en/latest/developing/install/).
Consult these docs as needed.

Note the prerequisites:

Before installing your development environment you’ll need to install each of these prerequisites:

* Git
* Node.js and `npm`
  - **For Linux**:
    - If using Debian/Ubuntu: Follow nodejs.org’s instructions for installing `node`.
      The `node` version provided in the Ubuntu repositories is outdated.
    - **For macOS**: Use Homebrew to install `node`.
* `Docker`: Follow the instructions detailed [here](https://docs.docker.com/engine/install/) to install.
* `pyenv`:
  - **For Linux**: Read [this document](https://github.com/pyenv/pyenv/blob/master/README.md) to install.
  - **For macOS**: Use Homebrew

**Your Node version in the shell in which you are developing must be more recent than 12.20.0**.
To manage Node versions, we suggest using [nvm](https://github.com/nvm-sh/nvm).

With pyenv, you will need to install **python version 3.8.12**.
From the `h/` directory:

```sh
pyenv install 3.8.12
pyenv init
```

Then reload your shell:

```sh
pyenv shell 3.8.12
```

**If pyenv has trouble finding the python binary**, you may need to add configuration to
either your `.bashrc` or your `.zshrc` as documented [here](https://stackoverflow.com/questions/51863225/pyenv-python-command-not-found).

After all is set, run:

```sh
make services
```

which launches the docker services needed to run `H`.

If this is your first time configuring and launching `H`, run:

```sh
make db # This will configure the database schema
```


If this is your first time, run `make dev` to install the dependencies (requires both `node` and `yarn`).
Otherwise, it will start the server on port 5000 (http://localhost:5000).

The `make dev` command will not start `H` in debug mode, i.e. you will not be able to run `pdb.set_trace()`.
To run `H` in debug mode, exit the `make dev` process and run:

```sh
tox -e dev --run-command 'gunicorn --paste conf/development-app.ini  'h:app:create_app' -b 0.0.0.0:5000'
```

You will have to exit and restart `tox` whenever changes are made to the code.
Additionally, in debug mode, certain functionalities may be restricted.
You will not be able to create and persist annotations from the client if `H` is running in debug mode,
for example.

To launch the shell and poke around in the database, run:

```sh
make shell
```

Now you can create an admin user from the shell. You will need an admin user to set up OAuth between `H`
and the Hypothesis client. Follow [these instructions](https://h.readthedocs.io/en/latest/developing/administration/).

Finally, log in as admin, and configure OAuth. Instructions can be found [here](https://h.readthedocs.io/en/latest/developing/integrating-client/).
Ensure that you export the `CLIENT_URL` and `CLIENT_OAUTH_ID` environment variables to the `h/` directory,
i.e. the same shell in which you launch the `H` dev server.

---

**Part two:**

First clone into the root of the Phoenix repository [our fork of the Hypothesis client](https://github.com/tosdr/client/tree/phoenix-integration)
_**(use the `phoenix-integration` branch)**_, then enter the directory:

```sh
git clone https://github.com/tosdr/client --branch=phoenix-integration ./client
cd client
```

If successful,run:

```sh
make dev
```

You will need a Node version that is more recent than `12.20.0`. **`H` has to be running**.
Instructions can be found [here](https://h.readthedocs.io/projects/client/en/latest/developers/developing.html#running-the-client-from-h), if needed.

---

## Database

_**This wiki has been deprecated. We are in the process of updating it.**_

All the details on the database schema can be found on the [wiki](https://github.com/tosdr/edit.tosdr.org/wiki/database).

---

## API

All the details on the API can be found [here](https://developers.tosdr.org/dev/restful-api)

---

## License

AGPL-3.0+ (GNU Affero General Public License, version 3 or later)

