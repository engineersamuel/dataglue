https://www.openshift.com/kb/kb-e1006-sync-new-git-repo-with-your-own-existing-git-repo

Feel free to change or remove this file, it is informational only.

Repo layout
===========
tmp/ - Temporary storage
public/ - Content (images, css, etc. available to the public)
config.ru - This file is used by Rack-based servers to start the application.
../data - For persistent data
.openshift/action_hooks/pre_build - Script that gets run every git push before the build
.openshift/action_hooks/build - Script that gets run every git push as part of the build process (on the CI system if available)
.openshift/action_hooks/deploy - Script that gets run every git push after build but before the app is restarted
.openshift/action_hooks/post_deploy - Script that gets run every git push after the app is restarted


Environment Variables
=====================

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


Notes about layout
==================
Every time you push, everything in your remote application path gets recreated
please store long term items (like an sqlite database) in ../data which will
persist between pushes of your repo.


Rails 3.0
===========

Option 1) (Recommended) Git push your application Gemfile/Gemfile.lock.  This will 
cause the remote OpenShift node to run bundle install --deployment to download and 
install your dependencies.  Each subsequent git push will use the previously 
downloaded dependencies as a starting point, so additional downloads will be a delta.

Option 2) Git add your .bundle and vendor/bundle directories after running 
'bundle install --deployment' locally.  Be sure to exclude any gems that have native 
code or ensure they can run on RHEL x86_64.


