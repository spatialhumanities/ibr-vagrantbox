#!/usr/bin/env bash

export PATH="$PATH:/sbin:/usr/sbin:usr/local/sbin"

###############################
# IBR PACKAGES & EXAMPLE DATA #
###############################

if [ ! -f /vagrant/data/downloaded ];
then
	echo 'Downloading example data...'
	cd /vagrant/
	wget -nv http://www.spatialhumanities.de/data.zip
	unzip data.zip
fi

if [ ! -f /vagrant/packages/downloaded ];
then
	echo 'Downloading IBR software components...'
	cd /vagrant/
	wget -nv http://www.spatialhumanities.de/packages.zip
	unzip packages.zip
fi

########
# bash #
########

sudo rm -rf /home/vagrant/.profile
sudo cp /vagrant/home/vagrant/.profile /home/vagrant/.profile

#######
# apt #
#######

sudo rm -rf /etc/apt/sources.list
sudo cp /vagrant/etc/apt/sources.list /etc/apt/sources.list

if [ ! -f /etc/apt/keyserverset ];
then
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886
	sudo touch /etc/apt/keyserverset
fi

echo 'Updating VM base system'

sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y clean
sudo apt-get -y autoremove

##########
# expect #
##########

if [ ! -f /usr/bin/expect ];
then
	echo 'Installing expect...'
	sudo apt-get -y install expect
fi

#######
# ntp #
#######

if [ ! -f /etc/init.d/ntp ];
then
	echo 'Installing ntp server...'
	sudo echo 'Europe/Berlin' > /etc/timezone
	sudo dpkg-reconfigure -f noninteractive tzdata
	sudo apt-get -y install ntp ntpdate
	sudo /etc/init.d/ntp stop
	sudo ntpdate 0.debian.pool.ntp.org
	sudo /etc/init.d/ntp start
else
	sudo /etc/init.d/ntp start
fi

#######
# svn #
#######

if [ ! -f /usr/bin/svn ];
then
	echo 'Installing subversion...'
	sudo apt-get -y install subversion
fi

#######
# git #
#######

if [ ! -f /usr/bin/git ];
then
	echo 'Installing git...'
	sudo apt-get -y install git
fi

#######
# vim #
#######

if [ ! -f /usr/bin/vim ];
then
	echo 'Installing vim...'
	sudo apt-get -y install vim
	sudo expect -f /vagrant/scripts/set-default-editor.expect
fi

sudo cp -fs /vagrant/home/vagrant/.vimrc /root/.vimrc
sudo cp -fs /vagrant/home/vagrant/.vimrc /home/vagrant/.vimrc

#########
# unzip #
#########

if [ ! -f /usr/bin/unzip ];
then
	echo 'Installing unzip...'
	sudo apt-get -y install unzip
fi

########
# pigz #
########

if [ ! -f /usr/bin/pigz ];
then
	echo 'Installing pigz...'
	sudo apt-get -y install pigz
fi

########
# htop #
########

if [ ! -f /usr/bin/htop ];
then
	echo 'Installing htop...'
	sudo apt-get -y install htop
fi

##########
# screen #
##########

if [ ! -f /usr/bin/screen ];
then
	echo 'Installing screen...'
	sudo apt-get -y install screen
fi

sudo rm -rf /home/vagrant/.screenrc
sudo cp /vagrant/home/vagrant/.screenrc /home/vagrant/.screenrc

######
# mc #
######

if [ ! -f /usr/bin/mc ];
then
	echo 'Installing midnight commander...'
	sudo apt-get -y install mc
fi

########
# JAVA #
########

if [ ! -f /usr/bin/java ];
then
	echo 'Installing Java...'
	echo 'oracle-java7-installer shared/present-oracle-license-v1-1 note' | debconf-set-selections
	echo 'oracle-java7-installer oracle-java7-installer/local string' | debconf-set-selections
	echo 'oracle-java7-installer shared/accepted-oracle-license-v1-1 boolean true' | debconf-set-selections
	echo 'oracle-java7-installer shared/error-oracle-license-v1-1 error' | debconf-set-selections
	echo 'oracle-java7-installer oracle-java7-installer/not_exist error' | debconf-set-selections

	sudo apt-get -y install oracle-java7-installer
	sudo apt-get -y install oracle-java7-set-default
else
	export JAVA_HOME=/usr/lib/jvm/java-7-oracle
fi

##################
# TOMCAT + MAVEN #
##################

if [ ! -f /etc/tomcat7/server.xml ];
then
	echo 'Installing Tomcat Application Server and Maven...'
	sudo export JAVA_HOME=/usr/lib/jvm/java-7-oracle
	sudo apt-get -y install tomcat7 tomcat7-admin maven
fi

##########
# APACHE #
##########

if [ ! -f /etc/apache2/apache2.conf ];
then

	echo 'Installing Apache Webserver...'

	# install apache2
	sudo apt-get -y install apache2 libapache2-mod-jk

	# install SSL tools
	sudo apt-get -y install ssl-cert

	# install OpenSSL
	sudo apt-get -y install openssl

	# install curl dev package
	sudo apt-get -y install libcurl4-openssl-dev

	# enable modules
	sudo a2enmod rewrite ssl headers

	# remove default index
	sudo rm -rf /var/www/index.html
fi

##########
# SESAME #
##########

if [ ! -f /var/lib/tomcat7/webapps/openrdf-sesame.war ];
then
	echo 'Installing Sesame RDF server...'
	sudo mkdir -p /usr/share/tomcat7/.aduna/
	sudo chown root:tomcat7 /usr/share/tomcat7/.aduna/
	sudo chmod g+w /usr/share/tomcat7/.aduna/
	cd /tmp/
	sudo wget -nv --trust-server-names "http://sourceforge.net/projects/sesame/files/Sesame%202/2.8.1/openrdf-sesame-2.8.1-sdk.tar.gz/download"
	tar -xzvf openrdf-sesame-2.8.1-sdk.tar.gz
	sudo mv openrdf-sesame-2.8.1/war/openrdf-sesame.war /var/lib/tomcat7/webapps/openrdf-sesame.war
	sudo mv openrdf-sesame-2.8.1/war/openrdf-workbench.war /var/lib/tomcat7/webapps/openrdf-workbench.war

	sudo /etc/init.d/tomcat7 restart

	# create project triple store
	sudo expect -f /vagrant/scripts/sesame-setup.expect
fi

################
# SPATIALSTORE #
################

if [ ! -f /var/lib/tomcat7/webapps/spatialstore.war ];
then

	echo 'Deploying Spatialstore...'

	# deploy spatialstore
	sudo cp -a /vagrant/packages/spatialstore.war /var/lib/tomcat7/webapps/spatialstore.war
	
	# link example rgb + rem panos
	sudo ln -s /vagrant/data/pano /var/www/pano

	# link pointcloud data
	sudo mkdir -p /var/tmp/pano/oberwesel/screenshot
	sudo chmod ugo+rwx /var/tmp/pano/oberwesel/screenshot
	sudo ln -s /vagrant/data/pano/oberwesel/pc /var/tmp/pano/oberwesel/pc

fi

####################
# ANNOTATIONSERVER #
####################

#if [ ! -f /var/lib/tomcat7/webapps/annotationserver.war ];
#then

#	echo 'Deploying Annotationserver...'

	# deploy annotationserver
#	sudo mv /vagrant/packages/annotationserver.war /var/lib/tomcat7/webapps/annotationserver.war

#fi

##########
# VIEWER #
##########

if [ ! -f /var/www/viewer/index.html ];
then

	echo 'Deploying Generic Viewer...'

	# cp and unzip generic viewer
	sudo cp -a /vagrant/packages/viewer.zip /var/www/
	cd /var/www/
	sudo unzip viewer.zip
	sudo rm viewer.zip
	sudo chown -R www-data:www-data /var/www/viewer/

fi

#######
# ASK #
#######

if [ ! -f /var/www/ask/index.html ];
then

	echo 'Deploying Ask...'

	# cp and unzip ask
	sudo cp -a /vagrant/packages/ask.zip /var/www/
	cd /var/www/
	sudo unzip ask.zip
	sudo rm ask.zip
	sudo chown -R www-data:www-data /var/www/ask/

fi

#########
# MYSQL #
#########

if [ ! -f /etc/mysql/my.cnf ];
then

	echo 'Installing MySQL...'

	echo 'mysql-server mysql-server/root_password password vagrant' | debconf-set-selections
	echo 'mysql-server mysql-server/root_password_again password vagrant' | debconf-set-selections
	sudo apt-get -y install mysql-client mysql-server

	echo 'Creating notebook database...'

	# create annotation database and pundit user
	sudo mysql -uroot -pvagrant -e "CREATE DATABASE semlibStorage COLLATE utf8_general_ci;"
	sudo mysql -uroot -pvagrant -e "CREATE USER 'vagrant'@'localhost' IDENTIFIED BY 'vagrant';"
	sudo mysql -uroot -pvagrant -e "GRANT USAGE ON *.* TO 'vagrant'@'localhost' IDENTIFIED BY 'sesa' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;"
	sudo mysql -uroot -pvagrant -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES ON semlibStorage.* TO 'vagrant'@'localhost';"

	# import structure for annotation data
	sudo mysql -uroot -pvagrant --default-character-set=utf8 semlibStorage < /vagrant/data/mysql/asTables.sql

fi

########################
# POSTGRESQL + POSTGIS #
########################

if [ ! -f /etc/init.d/postgresql ];
then

	echo 'Installing PostgreSQL and PostGIS...'

	sudo apt-get -y install postgresql postgresql-server-dev-9.1 build-essential libxml2-dev libproj-dev libjson0-dev libgeos-dev xsltproc docbook-xsl docbook-mathml libgdal-dev 
	cd /tmp/
	sudo wget -nv http://download.osgeo.org/postgis/source/postgis-2.0.6.tar.gz
	tar -xzvf postgis-2.0.6.tar.gz
	cd postgis-2.0.6
	sudo ./configure
	sudo make
	sudo make install
	sudo ldconfig
	sudo make comments-install
	sudo make clean
	sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/shp2pgsql
	sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/pgsql2shp
	sudo ln -sf /usr/share/postgresql-common/pg_wrapper /usr/local/bin/raster2pgsql
	sudo rm -rf /etc/postgresql/9.1/main/pg_hba.conf
	sudo cp /vagrant/etc/postgresql/9.1/main/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf
	sudo chown postgres:postgres /etc/postgresql/9.1/main/pg_hba.conf
	sudo /etc/init.d/postgresql restart

	echo 'Creating example database...'
	sudo psql -U postgres -h 127.0.0.1 -c "CREATE DATABASE oberwesel;"
	sudo psql -U postgres -h 127.0.0.1 -c "CREATE USER vagrant WITH SUPERUSER PASSWORD 'vagrant';"
	sudo pg_restore -U postgres -h 127.0.0.1 -d oberwesel /vagrant/data/postgresql/oberwesel.tar

fi 

################
# NODEJS + NPM #
################

if [ ! -f /usr/bin/nodejs ];
then

	echo 'Installing Node.js...'

	sudo apt-get -y install nodejs
	cd /usr/bin/
	sudo ln -s nodejs node
	cd /tmp/
	wget -nv --no-check-certificate https://npmjs.org/install.sh
	sudo chmod u+x install.sh
	sudo ./install.sh
fi

#########
# INTRO #
#########

if [ ! -f /var/www/index.html ];
then

	echo 'Setting up intro page of demo box...'

	cd /var/www/
	sudo cp /vagrant/var/www/index.html /var/www/index.html
	sudo cp -a /vagrant/var/www/images /var/www/
	sudo cp -a /vagrant/var/www/css /var/www/
	sudo cp -a /vagrant/var/www/js /var/www/
	sudo chown -R www-data:www-data /var/www/
fi

###########################################
# RESTART SERVICES WITH NEW CONFIGURATION #
###########################################

echo 'Restarting system services and daemons...'

## TOMCAT restart ##

sudo rm -rf /etc/default/tomcat7
sudo rm -rf /etc/tomcat7/server.xml
sudo rm -rf /etc/tomcat7/tomcat-users.xml
sudo rm -rf /etc/libapache2-mod-jk/workers.properties

sudo cp /vagrant/etc/default/tomcat7 /etc/default/tomcat7
sudo cp /vagrant/etc/tomcat7/server.xml /etc/tomcat7/server.xml
sudo cp /vagrant/etc/tomcat7/tomcat-users.xml /etc/tomcat7/tomcat-users.xml
sudo chmod o+r /etc/tomcat7/tomcat-users.xml
sudo cp /vagrant/etc/libapache2-mod-jk/workers.properties /etc/libapache2-mod-jk/workers.properties

sudo /etc/init.d/tomcat7 restart

## APACHE restart ##

sudo rm -rf /etc/apache2/sites-available/default
sudo rm -rf /etc/apache2/conf.d/wheezy64.conf

sudo cp /vagrant/etc/apache2/sites-available/default /etc/apache2/sites-available/default
sudo cp /vagrant/etc/apache2/conf.d/wheezy64.conf /etc/apache2/conf.d/wheezy64.conf

sudo /etc/init.d/apache2 restart

## MySQL restart ##

sudo rm -rf /etc/mysql/conf.d/wheezy64.cnf
cp /vagrant/etc/mysql/conf.d/wheezy64.cnf /etc/mysql/conf.d/wheezy64.cnf

sudo /etc/init.d/mysql restart

## PostgreSQL restart ##

sudo rm -rf /etc/postgresql/9.1/main/pg_hba.conf
sudo cp /vagrant/etc/postgresql/9.1/main/pg_hba.conf /etc/postgresql/9.1/main/pg_hba.conf
sudo chown postgres:postgres /etc/postgresql/9.1/main/pg_hba.conf
sudo /etc/init.d/postgresql restart

echo 'Provisioning finished.'

#########
# TODOS #
#########

# spatialstore
## apache: always redirect to /rest

# annotationserver
## check: http://old.thepund.it/documentation/deploy-and-configure-the-pundit-server/ - section RDF Repository Configuration

# put documentation of box on index page?

# get working wars
# put stuff online
# tear down / bring up
## vbguest plugin?
# sudo apt-get purge virtualbox*
# VM guest additions old version => purge and vbguest?
## vagrant plugin install vagrant-vbguest
## port forwarding?
## vagrant plugin install vagrant-triggers