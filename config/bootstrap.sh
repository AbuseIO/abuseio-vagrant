#!/usr/bin/env bash


# if you change the database credentials, also change them in abuseio.env
MYSQL_ROOT_PASSWORD='vagrant'
DB_USER='abuseio'
DB_NAME='abuseio'
SQL_DIR='/tmp'

echo "===== Installing AbuseIO dependencies ====="

# install dependencies
apt-get update
apt-get install debconf-utils

# mysql settings
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"

# install packages
DEBIAN_FRONTEND=noninteractive apt-get install -y \
	apache2 apache2-utils beanstalkd mysql-server mysql-client php5 php5-mysql \
	php-mail-mimedecode php5-cli php5-curl php5-mysql php-pear \
	fetchmail ssmtp supervisor php5-dev git php5-mcrypt unzip php5-intl

echo "===== Updating mysql config ====="

# update mysql config file and restart
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old #backup
sed s:127.0.0.1:0.0.0.0: /etc/mysql/my.cnf.old > /etc/mysql/my.cnf

service mysql restart

echo "===== Updating apache config ====="

cp /tmp/000-abuseio.conf /etc/apache2/sites-available
rm -f /etc/apache2/sites-enabled/000*
ln -s /etc/apache2/sites-available/000-abuseio.conf /etc/apache2/sites-enabled

a2enmod rewrite
a2enmod headers

# update envvars and restart
service apache2 stop

cp /etc/apache2/envvars /etc/apache2/envvars.old #backup
sed s:www-data:vagrant: /etc/apache2/envvars.old > /etc/apache2/envvars

service apache2 start

# add vagrant to the all the groups for ubuntu
cp /etc/group /etc/group.old
sed 's/ubuntu$/ubuntu,vagrant/' /etc/group.old > /etc/group

echo "===== Creating AbuseIO databse user ====="

# let the root mysql user login from anywhere
echo "grant all privileges on *.* to 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' with grant option;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD

# create db user and db
echo "create user '$DB_USER'@'localhost' identified by '$MYSQL_ROOT_PASSWORD';" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD
echo "create database $DB_NAME;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD
echo "grant all privileges on $DB_NAME.* to '$DB_USER'@'localhost';" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD

echo "===== Installing cronjobs ====="
crontab /tmp/crontab

echo "===== Installing fetchmailrc ====="
cp /tmp/fetchmailrc ~/.fetchmailrc
chmod 600 ~/.fetchmailrc

echo "===== Installing supervisor config ====="
cp /tmp/abuseio_queue_email.conf /etc/supervisor/conf.d/abuseio_queue_email.conf
supervisorctl reread
supervisorctl add abuseio_queue_emails
supervisorctl start abuseio_queue_emails

echo "===== Installing composer ======"
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo "===== installing dependencies ====="
pecl install mailparse-2.1.6
echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini
php5enmod mailparse
php5enmod mcrypt

echo "===== Installing ssmtp config files ====="
cp /tmp/ssmtp.conf /etc/ssmtp/ssmtp.conf
cp /tmp/revaliases /etc/ssmtp/revaliases

chmod 600 ~/.fetchmailrc

echo "===== Installing abuseio environment ======"
cp /tmp/.env /abuseio/.env

echo "===== Fixing file permisions ====="
#sudo chown -R vagrant:vagrant  /abuseio
sudo chmod -R 750 /abuseio/storage
sudo chmod 755 /abuseio/bootstrap/cache

echo "===== Abuseio Installation ====="
cd /abuseio
sudo -u vagrant composer update
cp /tmp/.env /abuseio/.env

cd /abuseio
sudo -u vagrant php artisan migrate:install
sudo -u vagrant php artisan migrate
sudo -u vagrant php artisan key:generate
sudo -u vagrant php artisan db:seed

echo "===== Apache2 restart ====="
service apache2 restart

echo "===== Done ====="

