## AbuseIO Vagrant

### What is it
The repository contains a Vagrantfile and some specific config files to create a development environment for AbuseIO using Vagrant.

#### About Vagrant
Vagrant is a tool for building complete development environments. With an easy-to-use workflow and focus on automation, Vagrant 
lowers development environment setup time, increases development/production parity, and makes the "works on my machine" excuse a 
relic of the past. For more information see [vagrantup.com](http://vagrantup.com)

### What to config

#### AbuseIO path
The setup expects that you already have a clone of [AbuseIO](https://github.com/AbuseIO/AbuseIO) on your system, the path to the repository
can be set withe ABUSEIO_PATH variable in Vagrantfile.


    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
    VAGRANTFILE_API_VERSION = "2"

    # Path to the AbuseIO repository
    ABUSEIO_PATH = "../AbuseIO"

#### email settings
The vagrant environment uses fetchmail and ssmtp instead of postfix to fetch and receive mail, you want to modify ssmtp.conf and fetchmailrc 
in the config directory, so it will use your own email credentials.

### Running the vagrant environment

Just type 

    vagrant up



