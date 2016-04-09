# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Path to the AbuseIO repository
ABUSEIO_PATH = "../AbuseIO"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3306, host: 3307

  # increase base memory to 2G
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
  end

  # Required for NFS to work, pick any local IP
  config.vm.network :private_network, ip: '192.168.50.50'
  # Use NFS for shared folders for better performance
  config.vm.synced_folder '.', '/vagrant', nfs: true

  #abuseio

  # copy database and config files to vagrant
  #config.vm.provision "file", source: ABUSEIO_PATH + "/sql/abuseio.sql", destination: "/tmp/abuseio.sql"
  config.vm.provision "file", source: "config/crontab", destination: "/tmp/crontab"
  config.vm.provision "file", source: "config/fetchmailrc", destination: "/tmp/fetchmailrc"
  config.vm.provision "file", source: "config/ssmtp.conf", destination: "/tmp/ssmtp.conf"
  config.vm.provision "file", source: "config/revaliases", destination: "/tmp/revaliases"
  config.vm.provision "file", source: "config/resolv.conf", destination: "/tmp/resolv/conf"
  config.vm.provision "file", source: "config/abuseio_queue_email.conf", destination: "/tmp/abuseio_queue_email.conf"
  config.vm.provision "file", source: "config/abuseio.env", destination: "/tmp/.env"
  config.vm.provision "file", source: "config/000-abuseio.conf", destination: "/tmp/000-abuseio.conf"

  # sync the abusio repository to the guest
  config.vm.synced_folder ABUSEIO_PATH, "/abuseio", nfs: true

  # execute bootstrap script
  config.vm.provision "shell", path: "config/bootstrap.sh"
end
