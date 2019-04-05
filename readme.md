## AbuseIO Vagrant

### What is it
The repository contains a Vagrantfile and some specific config files to create a development environment for AbuseIO 4.1 using Vagrant.

#### About Vagrant
Vagrant is a tool for building complete development environments. With an easy-to-use workflow and focus on automation, Vagrant 
lowers development environment setup time, increases development/production parity, and makes the "works on my machine" excuse a 
relic of the past. For more information see [vagrantup.com](http://vagrantup.com)

### What to config

#### AbuseIO path
The setup expects that you already have a clone of [AbuseIO](https://github.com/AbuseIO/AbuseIO) on your system, the path to the repository
can be set with the ABUSEIO_PATH variable in the Vagrantfile.


    # -*- mode: ruby -*-
    # vi: set ft=ruby :

    # Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
    VAGRANTFILE_API_VERSION = "2"

    # Path to the AbuseIO repository
    ABUSEIO_PATH = "../AbuseIO"

#### email settings
The vagrant environment uses fetchmail and ssmtp instead of postfix, to process mail, you will want to modify ssmtp.conf and fetchmailrc 
in the config directory, to use your own email credentials.

#### github settings
AbuseIO retrieves a lot of packages form github using composer, this will trigger a oath token request from github. You need to add
the github token to the config/composer-config.json file.

You can retrieve the token using

     # normal password authentification
     curl -u 'github user' curl -d '{"note":"GitHub OAuth token for composer"}' https://api.github.com/authorizations
     
     # two factor authentification, replace the 000000 in the header with your TOTP
     curl -u 'github user' curl --header "X-GitHub-OTP: 000000" -d '{"note":"GitHub OAuth token for composer"}' https://api.github.com/authorizations

### Running the vagrant environment

Just type 

    vagrant up

and connect to [http://localhost:8080/admin]


