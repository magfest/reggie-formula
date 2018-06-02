# -*- mode: ruby -*-
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "ubuntu/xenial64"

    config.vm.synced_folder ".", "/home/vagrant/reggie-formula", create: true

    # No good can come from updating plugins.
    # Plus, this makes creating Vagrant instances MUCH faster.
    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false
    end

    # This is the most amazing module ever, it caches anything you download with apt-get!
    # To install it: vagrant plugin install vagrant-cachier
    if Vagrant.has_plugin?("vagrant-cachier")
        # Configure cached packages to be shared between instances of the same base box.
        # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
        config.cache.scope = :box
    end

    config.vm.provider :virtualbox do |vb|
        vb.memory = 1536
        vb.cpus = 2

        # Suppress output of logfile "ubuntu-xenial-16.04-cloudimg-console.log"
        vb.customize ["modifyvm", :id, "--uartmode1", "disconnected"]

        # Allow symlinks to be created in /home/vagrant/reggie-deploy.
        # Modify "home_vagrant_reggie-deploy" to be different if you change the path.
        # NOTE: requires Vagrant to be run as administrator for this to work.
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_reggie-deploy", "1"]
    end

    config.vm.provision :salt do |salt|
        salt.colorize = true
        salt.masterless = true
        salt.minion_config = "vagrant/salt_minion.conf"
        salt.minion_id = "vagrant"
        salt.run_highstate = true
    end
end
