## Phoenix

### Overview

Feel free to skip ahead to **Development**, if you're more interested in technical implementation.

Phoenix is a web application to submit *points* to the Terms of Service; Didn't Read (ToS;DR) project. Think of a *point* as a succinct, easy-to-understand mini-conclusion sourced from the complex text of a privacy policy or terms of service agreement. For example, [You can retrieve an archive of your data](https://edit.tosdr.org/points/32363), or [Your personal data is used for automated decision-making, profiling or AI training
](https://edit.tosdr.org/points/33639)

Points are used by ToS;DR to analyse privacy policies and terms of service agreements across the web, then assign grades to online services based on their respect for users' privacy and personal data. By services, we mean websites and web applications. Think YouTube, or Amazon.

The heart of Phoenix is the user-submitted points (thanks to our awesome community), which are reviewed for accuracy and approved by our dedicated team of curators. Users submit points by annotating a service's documents, e.g. privacy policy, which Phoenix obtains and stores through web-scraping. 

Once a service has been comprehensively analysed in Phoenix, as determined by our curators, the grades appear on tosdr.org.

An A grade indicates that the service treats users with a high level of respect for their privacy and personal data. [DuckDuckGo](https://tosdr.org/en/service/222) is an example of an A-graded service. Grades D and E indicate that the services treat users with a low level of respect for their privacy and personal data. Examples include [CNN](https://tosdr.org/en/service/318) and [Facebook](https://tosdr.org/en/service/182). 

The grades are calculated based on an algorithm, which, in our case, is really just a simple list of conditions that factor in a balance of any given service's points. This algorithm is subject to change. You can read more about it on our [forum](https://tosdr.community/). We discuss how it has changed, and is changing, here: [Updating the algorithm for service grades – thoughts?](https://tosdr.community/t/updating-the-algorithm-for-service-grades-thoughts/2926/1)

**Infrastructure**

Phoenix is a Ruby on Rails application, with some Vue.js mixed in. It uses a Postgres database. 

For annotation, Phoenix relies on a customised instance of [Hypothesis](https://github.com/hypothesis), including a [fork of the Hypothesis web application repository](https://github.com/tosdr/h), and [a fork of the Hypothesis client](https://github.com/tosdr/client). 

This is a *new implementation*, [merged](https://github.com/tosdr/edit.tosdr.org/pull/1116) for use in production on May 17, 2023. That said, it is still experimental.

## Development

First, clone Phoenix :)

Requirements:
* [Docker](https://docs.docker.com/engine/install/) and [docker-compose](https://)
    * We rely on Docker as an attempt to be OS-agnostic
    * If you **are not able to use Docker**, install the following: 
        * Ruby 2.7.2
        * Rails (Phoenix uses version 5.2.5)
        * Bundler 2.2.6
        * Postgres 11.5
        * Node.js (to access Yarn) 12.20.0
        * Please refer to the [QUICKSTART.md](./QUICKSTART.md) guide for more information on manual set-up. If anything is missing, please let us know.
* Hypothesis
    * **Disclaimer:** Use of Hypothesis within Phoenix is not supported without Docker

### Hypothesis installation - part 1

H is the Hypothesis web service and api. 

1. To use it with Phoenix, clone [our fork of H](https://github.com/tosdr/h) into the same directory as the Phoenix clone.

    The official documentation for installing H is [here](https://h.readthedocs.io/en/latest/developing/install/). 

    Note the prerequisites:

    > Before installing your development environment you’ll need to install each of these prerequisites:
    > * Git
    > * Node and npm. On Linux you should follow nodejs.org’s instructions for installing node because the version of node in the standard Ubuntu package repositories is too old. On macOS you should use Homebrew to install node.
    > * Docker. Follow the instructions on the Docker website to install “Docker Engine - Community”.
    > * pyenv. Follow the instructions in the pyenv README to install it. The Homebrew method works best on macOS.

    Your **Node version in the shell in which you are developing must be 14.17.6**. To manage Node versions, we suggest [nvm](https://github.com/nvm-sh/nvm).

    With pyenv, you will need to install **python version 3.8.12**.

    **If pyenv has trouble finding the python binary**, you may need to add configuration to `.zshrc`, as documented [here](https://stackoverflow.com/questions/51863225/pyenv-python-command-not-found).
    
2. `cd h`
3. `docker create network dbs`

    In order for H and Phoenix to work together, they share a database, which is [defined](https://github.com/tosdr/h/blob/phoenix-integration/docker-compose.yml) over a docker network and launched with H.
5. `make services`
7. `make dev`
   
   This will start the server on port 5000 (http://localhost:5000)
   
   The `make dev` command will not start H in debug mode, i.e., you will not be able to run `pdb.set_trace()`.
   
   To run H in debug mode, exit the `make dev` process, and run `tox -e dev --run-command 'gunicorn --paste conf/development-app.ini  'h:app:create_app' -b 0.0.0.0:5000'`. 
   
   You will have to exit and restart `tox` whenever changes are made to the code. Additionally, in debug mode, certain functionalities may be restricted. You will not be able to create and persist annotations from the client if H is running in debug mode, for example.
   
   To launch the shell and poke around in the database, run `make shell`.
8. Create an admin user from the shell

   You will need an admin user to set up OAuth between H and the Hypothesis client. 
   
   Follow [these instructions](https://h.readthedocs.io/en/latest/developing/administration/).
7. Log in as admin, and configure OAuth

   Instructions [here](https://h.readthedocs.io/en/latest/developing/integrating-client/).
   
   Ensure that you export the environment variables `CLIENT_URL` and `CLIENT_OAUTH_ID` to the `h/` working directory.

### Hypothesis installation - part 2
 
1. Clone [our fork of the Hypothesis client](https://github.com/tosdr/client) into the same directory as Phoenix and H.
2. `cd client` and `make dev`
    
    You will need Node version 14.17.6. H will also have to be running.
    
    Instructions are [here](https://h.readthedocs.io/projects/client/en/latest/developers/developing.html#running-the-client-from-h), if needed.
    
### Running Phoenix

The following steps should be completed from the working directory of `edit.tosdr.org/`

If you have installed [Docker compose](https://docs.docker.com/compose/install/), getting the application running involves two steps, after which it can be started with a single command in the future.

To prepare the application, run the following command inside the repository folder to build it and initialise the database:

    $ docker-compose build

From then on, you can start the application by running:

    $ docker-compose up

(Add the `--build` argument if you add or remove dependencies.)

So,

1. `docker-compose up`

     This will start the server on port 9090 (http://localhost:5000)
     
2. Create your user via the sign-up page
3. Confirm your user manually
    * `docker-compose run web rails c`
    * Find your user: `user = User.find_by_username('your_username')`
    * Confirm user: `user.confirm`

4. Sign-in

At the moment, you have to create your own data via the web interface or the rails console (`docker-compose run web rails c`), but we are working on a proper seed so that this will no longer be the case. 

To **annotate** a service, you will need to: create a service, create a document for that service, create a topic, and create a case that belongs to the topic.

For a demonstration of how annotations work, feel free to [inspect the video attached to this PR](https://github.com/tosdr/edit.tosdr.org/pull/1116).

## Database

All the details on the database schema can be found on the [wiki](https://github.com/tosdr/edit.tosdr.org/wiki/database).

## API

All the details on the API can be found on the [wiki](https://github.com/tosdr/edit.tosdr.org/wiki/api)

## Core developers
* [Chris](https://github.com/piks3l/)
* [Jesse](https://github.com/JesseWeinstein)
* [Madeline](https://github.com/madoleary)
* [Michiel](https://github.com/michielbdejong)
* [Vincent](https://github.com/vinnl)

### Hosting
* https://edit.tosdr.org (production)

## License

AGPL-3.0+ (GNU Affero General Public License, version 3 or later)

