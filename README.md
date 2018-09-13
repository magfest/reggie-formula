# reggie-formula

SaltStack formula for Reggie, MAGFest's registration and management system.


# Reggie Development Environment

This is the officially supported method of setting up a development
environment for Reggie. It will create a deployment config that is using
the same plugins, and nearly identical configuration, as our production
servers. Once deployed, you can run a command to update all repositories
to the latest changes from GitHub.


## Getting Started

First, install all this stuff:

* [Git](https://git-scm.com)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)

It's recommended that you have a fast Internet connection, at least
4gb of RAM, and a fast computer for this.


## Choose an Event and a Year

This deploy supports multiple events with different configurations. Pick
an event name from the list of valid names (super, labs, west, stock)
and any valid year (2019, 2020).

You may also choose an unsupported event name. For instance, if you want
to develop a Reggie plugin for a non-MAGFest event. Be aware that, while
everything should still work, using an unsupported event name will
generate a barebones configuration.


## Windows Instructions

1. Open a git BASH terminal by clicking Start menu and typing 'git bash'.
   You should see a black command prompt window with green text.

2. Clone the repository somewhere on your local computer. You can do this
   by opening a command prompt and running the following commands:
   ```
   cd C:\wherever\you\want\your\project\to\live\

   git clone https://github.com/magfest/reggie-formula

   cd reggie-formula
   ```
   ([More Instructions](https://help.github.com/articles/cloning-a-repository/) if you need them)

3. Follow the section named 'Common Instructions' below.


##  Linux/Mac Instructions

1. Clone the repository somewhere on your local computer. You can do this
   by opening a command prompt and running the following commands:
   ```
   cd /home/myusername/somewhere/

   git clone https://github.com/magfest/reggie-formula

   cd reggie-formula
   ```
   ([More Instructions](https://help.github.com/articles/cloning-a-repository/) if you need them)

2. Follow the section named 'Common Instructions' below.


## Common Instructions (Windows/Linux/Mac/Cygwin/MingW)

1. Type ```./reggie_up.sh desired_event_name desired_event_year``` from the terminal.
   For example, to install MAGStock, you would type: ```./reggie_up.sh stock 2018```.
   (_This step may take awhile._)
2. After the install completes, you can login to Reggie with
   username 'magfest@example.com' and password 'magfest'.

Installation complete!


## To SSH into the machine

From the command prompt, type ```vagrant ssh``` to access the running machine

Now that things are fully installed, check out the [development doc](DEVELOPMENT.md)
for more info on what to do next. If you're looking for a good Integrated
Development Environment (IDE), check out the [doc on configuring PyCharm].


## Troubleshooting

* If you have previous deployments, you must ensure those VMs are stopped.
  Either type 'vagrant halt' from their project directories, or open the
  Virtualbox program from the start menu and power off any running VMs.

* If you see any Virtualbox errors like 'unable to start virtual machine'
  when starting the process, or anything about 'VMX' or 'hardware acceleration',
  you may need to make sure that hardware virtualization acceleration/extensions
  [are enabled](https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=virtualbox%20vtx%20disabled%20in%20bios)
  in your computer's BIOS.
