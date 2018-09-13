# Using PyCharm for Reggie Development

You can use any development environment you want to develop Reggie.

[PyCharm](https://www.jetbrains.com/pycharm/) is popular as an IDE
for a variety of reasons include ease of use for running unit tests,
code completion, debugging, etc...

Before starting here, make sure you've followed the setup instructions
from the [README](README.md).


## Quick 'n Dirty Setup PyCharm For Debugging
1. Configure your remote interpreter for Vagrant by going to Preferences
2. Under Project->Project Interpreter add a Remote Interpreter
3. Select Vagrant and put your python path as `/home/vagrant/reggie-formula/reggie_install/env/bin/python`
4. Edit your configurations
5. Add a python interpreter, and name it sideboard if you'd like
6. Set the script to one located at `reggie_install/sideboard/run_server.py`
7. Select your python interpreter as Python 3.6.5
8. Set your working directory as `reggie_install/sideboard`
9. You should be able to run Reggie from Pycharm now! Good luck!


# Setup PyCharm For Development

Make sure the virtual machine is running (use 'vagrant up' to bring it up).
Make sure you are running a recent version of PyCharm Professional 2016.2
or higher (not community edition).

1. Open Pycharm
   Note: You are going to see some warning messages about 'can't find git
   version control roots' for a couple of projects, that's OK just ignore
   those. Also dismiss anything about docker.

2. File->Open and select the folder 'reggie-formula' (or whatever you named it)

3. File->Settings and under Project:rams, click Project Interpreter

4. next to Project Interpreter, click the gear icon:

![image](https://cloud.githubusercontent.com/assets/5413064/17230985/51e13e0a-54ed-11e6-8c5f-f0f5198be9ac.png)

5. Click 'Add Remote'

6. Click the 'Vagrant' checkbox

7. Under 'vagrant instance folder', select your project folder:

![image](https://cloud.githubusercontent.com/assets/5413064/17231155/38f56be0-54ee-11e6-9ac0-3a280d0e1f48.png)

8. The 'vagrant host URL field' should now switch automatically to
   `ssh://vagrant@127.0.0.1:2222`

9. For 'python interpreter path', either paste or browse to:
   `/home/vagrant/reggie-formula/reggie_install/env/bin/python`

10. Hit OK and exit the system settings.  You may see some activity and
    messages of PyCharm working, this is normal and may take a minute or two
    to process.


### One-time setup is now complete! Now you can do the following to debug in PyCharm

Anytime you restart vagrant, you will need to stop Reggie from running in the background.

1. In PyCharm, click Tools -> External Tools -> systemctl

![image](https://cloud.githubusercontent.com/assets/5413064/17231311/28436f80-54ef-11e6-930d-4b3ab293ae1b.png)

This will stop Reggie from running as a daemon and allow you to take
control of it from PyCharm.


# Debugging in Pycharm

1. In the upper right hand corner, click the dropdown that has the PyCharm
configurations and select 'sideboard':

![image](https://cloud.githubusercontent.com/assets/5413064/17231343/6a21b682-54ef-11e6-8499-e030e794c60b.png)

2. Click the 'Debug' icon (it looks like a green bug)

You are now running ubersystem inside pycharm!  You can set breakpoints
and view the debug output.


# Running Unit Tests in Pycharm

This is basically the same procedure as debugging.

1. Select a unit test configuration:

![image](https://cloud.githubusercontent.com/assets/5413064/17231395/9218ae7a-54ef-11e6-8bba-d2bc58dde647.png)

2. Click the 'Debug' icon to run the unit tests.  You can set breakpoints inside the unit tests as well!


# Source Control

All repositories (reggie-formula, infrastructure, sideboard, and all plugins)
show up at the same time and you can do most git operations from within
pycharm. Click the 'version control' button at the bottom of the screen to
explore. PyCharm is incredibly adept at dealing with having a complex setup
of working on multiple repositories at the same time.

To update all of your projects from github:

1. Click the bottom right source control dialog:

![image](https://cloud.githubusercontent.com/assets/5413064/17231510/58e1d50e-54f0-11e6-8175-8e215762791a.png)

2. Make sure everything is set to either 'master' or a branch that exists in github.

3. Click the 'Update Project' button in the upper right to pull changes from github:

![image](https://cloud.githubusercontent.com/assets/5413064/17231489/31ec3174-54f0-11e6-8a22-d694fef941d1.png)


# Re-deploying

If there are config changes introduced from github (this happens from time
to time), or if you want to make sure you have the very latest, then
follow this procedure to re-deploy. You'll need a decently fast Internet
connection as this process will pull down stuff from github.

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

8. Click the 'debug' or 'run' icon in PyCharm and you should be up and running again.

You can also do some other stuff we will document later like running with
code coverage + unit tests to show you which lines of code are and aren't
being hit.


# Troubleshooting:

If you see 'Private key file not found' when setting up, please upgrade
your PyCharm, there was a bug in older versions.

If things are in general starting to get weird, check that you have
definitely clicked on the 'reggie-formula' directory when you opened the
project.  If you open any other directory THINGS WILL START GETTING WEIRD.
