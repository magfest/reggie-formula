# Systemd

Reggie by default runs as several processes controlled by a program
called Systemd. Systemd runs Reggie as a series of daemons automatically
on system start.

There are 3 different daemons that comprise Reggie:
* `reggie-web` - The web server component of Reggie
* `reggie-scheduler` - The background task scheduler component of Reggie
* `reggie-worker` - The background task worker component of Reggie

For development purposes, you will want to disable `reggie-web`.
Type the following:
```
sudo systemctl stop reggie-web
```

Now that `reggie-web` is disabled, you need to run the server manually. This
is nice for development, because it prints all logging output to the console.

# Running the Server

To run ubersystem manually, type:
```
run_server
```

It's a bash alias for the following:
```
alias run_server='/home/vagrant/reggie-formula/reggie_install/env/bin/python /home/vagrant/reggie-formula/reggie_install/sideboard/run_server.py'
```


# Directory Structure

Once everything is fully deployed, the folder structure that you can access
from the Host OS  (i.e. your Windows/Mac machine or whatever host OS you
are using) will look like this:

- reggie-formula - this repository
- reggie-formula/reggie_install - a repository containing sideboard
- reggie-formula/reggie_install/plugins - a folder which contains other repositories which are Reggie plugins
- reggie-formula/reggie_install/plugins/uber - the main Reggie plugin, where most of the important code is


# How to Update Reggie Config

Reggie reads from development.ini when it starts up, which overrides
anything in development-defaults.ini, which overrides anything in
configspeci.ini.

You can put new stuff in development.ini by modifying the YAML files under
infrastructure/reggie_config.


# sep Commands

A variety of Reggie commands are available from the command line through the
`sep` utility. From inside vagrant, type `sep` to see a list of available
commands.
