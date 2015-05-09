#!/usr/bin/env bash

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
	apache2 mysql-server mysql-client php5 php5-mysql \
	php-mail-mimedecode php5-cli php5-curl php5-mysql \
	fetchmail ssmtp

echo "===== Updating mysql config ====="

# update mysql config file and restart
cp /etc/mysql/my.cnf /etc/mysql/my.cnf.old #backup
sed s:127.0.0.1:0.0.0.0: /etc/mysql/my.cnf.old > /etc/mysql/my.cnf

service mysql restart

echo "===== Linking Apache DocumentRoot to AbuseIO ====="

# link the abuseio www dir to /var/www
if ! [ -L /var/www/html ]; then
  rm -rf /var/www/html
  ln -fs /abuseio/www /var/www/html
fi

echo "===== Creating AbuseIO user and database ====="

# let the root mysql user login from anywhere
echo "grant all privileges on *.* to 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD' with grant option;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD

# create db user and db
echo "create user '$DB_USER'@'localhost';" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD
echo "create database $DB_NAME;" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD
echo "grant all privileges on $DB_NAME.* to '$DB_USER'@'localhost';" | mysql --user=root --password=$MYSQL_ROOT_PASSWORD

# load the database, already copied to /tmp
OLD_PWD=`pwd`
cd $SQL_DIR
for sql in $( ls *.sql ); do
	mysql --user=root --password=$MYSQL_ROOT_PASSWORD $DB_NAME < $sql
done
cd $OLD_PWD

echo "===== Installing cronjobs ====="
crontab /tmp/crontab

echo "===== Installing fetchmailrc ====="
cp /tmp/fetchmailrc ~/.fetchmailrc
chmod 600 ~/.fetchmailrc

echo "===== Installing ssmtp config files ====="
cp /tmp/ssmtp.conf /etc/ssmtp/ssmtp.conf
cp /tmp/revaliases /etc/ssmtp/revaliases

chmod 600 ~/.fetchmailrc

echo "===== Fixing file modes ====="
chmod 777 /abuseio/tmp /abuseio/archive

echo "===== Done ====="

