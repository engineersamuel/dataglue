### Introduction

Dataglue is an open source sandbox data visualization application.


The objective of this project is to be able to consume data from any datasource and quickly visualize in most any manner desired.

### Features
* Reading from SQL and NoSQL datasources
* Ability to multiplex time series data
* Single page design faciliting graph changes on the fly with D3
* No ETL required for working with data sets that don't require ETL
* Deploys locally and to Openshift


### Screenshots

### Deployment

https://www.openshift.com/kb/kb-e1006-sync-new-git-repo-with-your-own-existing-git-repo

Create a ~/.dataglue-settings.yml in your home directory if you are deploying locally or in $OPENSHIFT_DATA_DIR/.dataglue-settings.yml if deploying to Openshift.

    env: 'dev'

    mysql_refs: 
        - name: "mysqlConnA"
          host: "someaddress.com"
          user: "someuser"
          pass: "somepass"
          db: "somedb"


### Repo layout
* tmp/ - Temporary storage
* public/ - Content (images, css, etc. available to the public)
* config.ru - This file is used by Rack-based servers to start the application.
* ../data - For persistent data
* Script that gets run every git push before the build
    .openshift/action_hooks/pre_build
* Script that gets run every git push as part of the build process (on the CI system if available)
    .openshift/action_hooks/build 
* Script that gets run every git push after build but before the app is restarted
    .openshift/action_hooks/deploy
* Script that gets run every git push after the app is restarted
    .openshift/action_hooks/post_deploy


### Environment Variables
OpenShift provides several environment variables to reference for ease
of use.  The following list are some common variables but far from exhaustive:

    ENV['OPENSHIFT_APP_NAME']  - Application name
    ENV['OPENSHIFT_DATA_DIR']  - For persistent storage (between pushes)
    ENV['OPENSHIFT_TMP_DIR']   - Temp storage (unmodified files deleted after 10 days)

When embedding a database using 'rhc cartridge add', you can reference environment
variables for username, host and password:

If you embed MySQL, then:

    ENV['OPENSHIFT_MYSQL_DB_HOST']      - DB host
    ENV['OPENSHIFT_MYSQL_DB_PORT']      - DB Port
    ENV['OPENSHIFT_MYSQL_DB_USERNAME']  - DB Username
    ENV['OPENSHIFT_MYSQL_DB_PASSWORD']  - DB Password

To get a full list of environment variables, simply add a line in your
    .openshift/action_hooks/build script that says "export" and push.


### Notes about layout
Every time you push, everything in your remote application path gets recreated
please store long term items like an sqlite database in data which will
persist between pushes of your repo.

### Starting with this git repo and pushing to Openshift
* Clone dataglue from github
* Create the openshift project in a seperate directory so Openshift will create the app on the server
    `rhc create-app -g <gear size name> dataglue "http://cartreflect-claytondev.rhcloud.com/reflect?github=wshearn/openshift-origin-cartridge-nodejs"`
* Add the mongo cartridge:
    `rhc cartridge add mongodb-2.2 -a dataglue`
* SSH into openshift mongo and add the master ref pointing to ENV creds for the mongo cartridge
~~~
rhc ssh dataglue
vim $OPENSHIFT_DATA_DIR/.dataglue-settings.yml

    env: 'dev'

    master_database:
        dev:
            type: 'mongo'
            host: "127.0.0.1"
            port: "27017"
            user: ""
            pass: ""
            db: "dataglue"
            collection: "refs"
            cache: "cache"
        prod:
            type: 'mongo'
            host: "$OPENSHIFT_MONGODB_DB_HOST"
            port: "$OPENSHIFT_MONGODB_DB_PORT"
            user: "$OPENSHIFT_MONGODB_DB_USERNAME"
            pass: "$OPENSHIFT_MONGODB_DB_PASSWORD"
            db: "$OPENSHIFT_APP_NAME"
            collection: "ref"
            cache: "cache"
~~~
* Go to the directory you cloned dataglue to and open the .git/config and add the openshift remote
~~~
[remote "openshift"]
    fetch = +refs/heads/*:refs/remotes/origin/*
    url = ssh://<hash>@<path to openshift>.com/~/git/dataglue.git/
~~~
* Force push to openshift
~~~
git push -f openshift
~~~



### Project creation and internals
To create this github project which is also pushed to openshift:

* Cartridge https://github.com/wshearn/openshift-origin-cartridge-nodejs
* Create the github project and do the intial push
* Create the openshift project in a seperate directory so Openshift will create the app on the server
    `rhc create-app -g <gear size name> dataglue "http://cartreflect-claytondev.rhcloud.com/reflect?github=wshearn/openshift-origin-cartridge-nodejs"`
* Add the mongo cartridge:
    `rhc cartridge add mongodb-2.2 -a dataglue`
* In your project directory:
    `git pull ssh://<hash>@<path to openshift>.com/~/git/dataglue.git/`
* git commit -a -m "fixing OpenShift merge"
* git push ssh://<hash>@<path to openshift>.com/~/git/dataglue.git/ master
* Edit the .git/config and add

    [core]
        repositoryformatversion = 0
        filemode = true
        bare = false
        logallrefupdates = true
    [remote "all"]
        url = git@github.com:engineersamuel/dataglue.git
        url = ssh://<hash>@<path to openshift>.com/~/git/dataglue.git/
    [remote "origin"]
        fetch = +refs/heads/*:refs/remotes/origin/*
        url = git@github.com:engineersamuel/dataglue.git
    [remote "openshift"]
        fetch = +refs/heads/*:refs/remotes/origin/*
        url = ssh://<hash>@<path to openshift>.com/~/git/dataglue.git/
    [branch "master"]
        remote = origin
        merge = refs/heads/master
* Bower
 * For zsh, to ~/.zshrc add alias bower='noglob bower'

### Testing
`npm install`
`grunt mochaTest`

### Migrating in Openshift

If needing to change gears or change cartridges or update cartridges, follow these steps:

https://www.openshift.com/kb/kb-e1052-how-do-i-migrate-my-app
* `rhc snapshot save -a dataglue`
* mongo dump as well, as the snapshot did not appear to save the mongo data
* `rhc delete-app dataglue`
* `rhc create-app -g <gear name|int_general_medium> dataglue "http://cartreflect-claytondev.rhcloud.com/reflect?github=wshearn/openshift-origin-cartridge-nodejs"`
* `rhc cartridge add mongodb-2.2 -a dataglue`
* `rhc snapshot restore -a dataglue -f /tmp/dataglue.tar.gz`
* Then Update the .git/config openshift ssh references to point to the new openshift app ssh git location.  This can be found by logging into openshift and going to the app.

### References
* [Getting Started with Openshift](https://www.openshift.com/get-started)
* [Deploying a Sinatra application on OpenShift](https://www.openshift.com/kb/kb-e1009-deploying-a-sinatra-application-on-openshift)
* [Github Openshift Sinatra Example](https://github.com/openshift/sinatra-example)
* [Existing project with Openshift](https://gist.github.com/ryanj/5267357)
* [Sync new git repo with your own existing git repo](https://www.openshift.com/kb/kb-e1006-sync-new-git-repo-with-your-own-existing-git-repo)
* [RequireJS + Bower + Masonry example](https://github.com/gigablox/angular-art-gallery)

### Research

* [Laravel](http://laravel.com/) -- Programmatically create SQL querys in Ruby
* [Knex.js](http://knexjs.org/) -- Node package for programmatically creating SQL

### License

(Apache License, Version 2.0)

Copyright 2013 Samuel Mendenhall

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
