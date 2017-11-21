#!/usr/bin/env bash


# if you change the database credentials, also change them in abuseio.env
MYSQL_ROOT_PASSWORD='ubuntu'
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
	nginx beanstalkd mysql-server mysql-client\
	php php-mail-mimedecode php-cli php-curl php-mysql php-pear php-pgsql php-intl php-bcmath\
	php-dev php-mcrypt php-mbstring php-fpm php-zip git unzip fetchmail supervisor

echo "===== Updating mysql config ====="

# update mysql config file and restart
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old #backup
sed s:127.0.0.1:0.0.0.0: /etc/mysql/my.cnf.old > /etc/mysql/my.cnf

service mysql restart

echo "===== Updating Nginx config ====="

cp /tmp/abuseio.conf /etc/nginx/sites-available
rm -f /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/abuseio.conf /etc/nginx/sites-enabled

echo "===== Tweaking php-fpm ====="
sed -i -e "s/listen = \/run\/php\/php7.0-fpm.sock/listen = 127.0.0.1:9000/g" \
    /etc/php/7.0/fpm/pool.d/www.conf

echo "===== Creating AbuseIO database user ====="

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

echo "===== Installing composer and GitHub OATH ======"
cd /tmp
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
sudo -u ubuntu mkdir /home/ubuntu/.composer
sudo -u ubuntu cp /tmp/config.json /home/ubuntu/.composer
rm -rf /root/.composer
ln -s /home/ubuntu/.composer /root/.composer

echo "===== tweak mbstring ====="

cp /usr/include/php/20151012/ext/mbstring/libmbfl/mbfl/mbfilter.h .
awk '/#define MBFL_MBFILTER_H/{print;print "#undef HAVE_MBSTRING\n#define HAVE_MBSTRING 1";next}1' \
    mbfilter.h > /usr/include/php/20151012/ext/mbstring/libmbfl/mbfl/mbfilter.h

echo "===== installing mailparse ====="

pecl install mailparse
echo "extension=mailparse.so" > /etc/php/7.0/mods-available/mailparse.ini
phpenmod mailparse
phpenmod mcrypt

echo "===== Installing abuseio environment ======"
cp /tmp/.env /abuseio/.env

echo "===== Fixing file permisions ====="
#sudo chown -R ubuntu:ubuntu  /abuseio
sudo chmod -R 750 /abuseio/storage
sudo chmod 755 /abuseio/bootstrap/cache

echo "===== Abuseio Installation ====="
cd /abuseio

echo "===== Workaround MacOS NFS ====="
# https://github.com/mitchellh/vagrant/issues/8061#issuecomment-291954060
sudo -u ubuntu find . -type d \
	-exec touch '{}'/.touch ';' \
	-exec rm -f '{}'/.touch ';' \
	2>/dev/null

sudo -u ubuntu composer update
cp /tmp/.env /abuseio/.env

cd /abuseio
sudo -u ubuntu php artisan migrate:install
sudo -u ubuntu php artisan migrate
sudo -u ubuntu php artisan key:generate
sudo -u ubuntu php artisan db:seed

echo "===== Nginx / php-fpm restart ====="
service php7.0-fpm restart
service nginx restart

echo "===== Done ====="

