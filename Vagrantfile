# -*- mode: ruby -*-
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    config.vm.box = "bento/ubuntu-18.04"
    config.vm.hostname = "localhost"

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

        # Allow symlinks to be created in /home/vagrant/reggie-formula.
        # Modify "home_vagrant_reggie-formula" to be different if you change the path.
        # NOTE: requires Vagrant to be run as administrator for this to work.
        vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/home_vagrant_reggie-formula", "1"]
    end

    config.vm.provision :shell, inline: <<-SHELL
        set -e
        export DEBIAN_FRONTEND=noninteractive
        export DEBIAN_PRIORITY=critical
        sudo -E apt-get -qy update
        sudo -E apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
        sudo -E apt-get -qy autoclean
    SHELL

    config.vm.provision :salt do |salt|
        salt.colorize = true
        salt.masterless = true
        salt.minion_config = "vagrant/salt_minion.conf"
        salt.minion_id = "vagrant"
        salt.run_highstate = true
    end

    config.vm.post_up_message = <<-MESSAGE
        All done!

        To login to your new development machine run:
            vagrant ssh

        Once logged in, the machine can be reconfigured using:
            sudo salt-call --local state.apply

        Or using the shortcut alias for "sudo salt-call --local":
            salt-local state.apply

        Or using the shortcut alias for "salt-local state.apply":
            salt-apply

    MESSAGE
end
