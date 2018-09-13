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
`infrastructure/reggie_config`.


# Re-Deploying

If there are local config changes, or changes introduced from github
(this happens from time to time), or if you want to make sure you have the
very latest, then follow this procedure to re-deploy. You'll need a decently
fast Internet connection as this process will pull down stuff from github.

At some future point, we're going to make this process a bit more automated.

2. Open a command prompt or terminal and change directory to reggie-formula.

3. Run the `vagrant up` command if the vagrant machine isn't already running.

4. Run `vagrant ssh` to ssh into the machine.

5. Type `sudo salt reggie state.apply`. (_This may take awhile_.) This
   will bring your deploy up to date with the latest code, apply all
   configuration (YAML/INI) changes, install any new plugins that were
   added, and a bunch of other stuff. It should end with a pristine copy
   of everything deployed and ready to rock.

      a. If the command times out, make a note of the job id (JID). You can
         check for results with the following command:
         `sudo salt-run --out highstate jobs.lookup_jid JID`

6. If you are planning on running the Reggie server from inside PyCharm
   (so you can debug it, for instance) then you'll need to turn off the
   server which the deploy auto-starts by typing `sudo systemctl stop reggie-web`
   from inside vagrant.  If not, skip this step.

Deploy is now finished! You can close the command prompt.

7. If you were working on local changes, switch back to those branches,
   or unstash your changes.


# Running Unit Tests

You can run the test suite using `tox`.


# sep Commands

A variety of Reggie commands are available from the command line through the
`sep` utility. From inside vagrant, type `sep` to see a list of available
commands.
