#!/bin/bash
# Autor: Michael Karrer
# Date: 25.08.2013
# Version: 1.3
# Description: This Script prepares an Ubuntu 12.04 LTS Server for OpenERP 7.0 (and UP)
#############

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path where this script is in, thus /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTPATH=$(cd ${0%/*} && pwd -P)
echo -e "\n##### START SCRIPT:  ##### \n\n$SCRIPT\nIN PATH: $SCRIPTPATH\n"


# Allow the user to stop the script:
/bin/echo -e "Would you like to prepare your Ubuntu 12.04 LTS Server for OpenERP ( Y / N ) :"
read answer
while [ "$answer" != "y" ] && [ "$answer" != "Y" ]
do
    echo "Please enter Y (Yes) or N (No)"
    read answer
    if [ "$answer" == "n" ] || [ "$answer" == "N" ]
    then
        echo "EXIT SCRIPT - Nothing happened"
        exit 1
    fi
done


# create the basic directory for OpenERP and a log file to monitor the process
OA_BASEDIR="/opt/openerp"
OA_LOGFILE="${OA_BASEDIR}/oe-prepare_system.log"
# Change to the OpenERP path
if cd $OA_BASEDIR ; then
    echo -e "Changed directory to $OA_BASEDIR"
else
    if mkdir $OA_BASEDIR ; then
	    echo -e "Created directory $OA_BASEDIR"
	    cd $OA_BASEDIR
	    echo -e "Changed directory to $OA_BASEDIR"
    else
        echo -e "Could not create directory $OA_BASEDIR. Exiting programm"
	    exit
    fi
fi


# START By Joe
# Add important apt sources for minimal ubuntu 12.04 lts installs
if ! egrep "precise.*multiverse"  /etc/apt/sources.list >> $OA_LOGFILE; then
    echo "deb http://de.archive.ubuntu.com/ubuntu precise main multiverse" >> /etc/apt/sources.list
fi

if ! egrep "precise-backports"  /etc/apt/sources.list >> $OA_LOGFILE; then
    echo "deb http://de.archive.ubuntu.com/ubuntu precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
fi

if ! egrep "deb-src.*precise.*restricted"  /etc/apt/sources.list >> $OA_LOGFILE; then
    echo "deb-src http://de.archive.ubuntu.com/ubuntu precise main restricted" >> /etc/apt/sources.list
fi

if ! egrep "deb-src.*precise-updates.*restricted"  /etc/apt/sources.list >> $OA_LOGFILE; then
    echo "deb-src http://de.archive.ubuntu.com/ubuntu precise-updates main restricted" >> /etc/apt/sources.list
fi


# Check if the locale is utf8 and stop the script if not
locale_set=false
if ! [ -e "/etc/default/locale" ]; then
    touch /etc/default/locale
    locale_set=true
fi

if ! egrep -i "LANG=.*UTF-8" /etc/default/locale >> $OA_LOGFILE; then
    echo 'LANG="en_US.UTF-8"' >> /etc/default/locale
    locale_set=true
fi

if ! egrep -i "LANGUAGE=...+" /etc/default/locale >> $OA_LOGFILE; then
    echo 'LANGUAGE="en_US.UTF-8"' >> /etc/default/locale
    locale_set=true
fi

locale-gen en_US.UTF-8 >> $OA_LOGFILE
locale-gen de_AT.UTF-8 >> $OA_LOGFILE
update-locale >> $OA_LOGFILE
if [ "$locale_set" = true ]; then
    echo "Bitte beenden Sie diese SSH Session und Loggen sie sich neu ein damit die LOCALE settings aktiv werden"
    echo "Dies ist zwingend notwendig damit die Postgresql mit den richtigen locale Installiert wird"
    exit 2
fi
# END By Joe



# Install nginx and remove apache
echo -e "Now we are upgrading this ubuntu install: PLEASE BE PATIENT! \n USE: tail -f /opt/openerp/oe-prepare_system.log to see what's happening\n"
echo -e "Installing nginx - Please make sure any version of apache is removed!"
yes | apt-get remove apache2 apache2-mpm-event apache2-mpm-prefork apache2-mpm-worker >> $OA_LOGFILE
yes | apt-get update >> $OA_LOGFILE
yes | apt-get upgrade >> $OA_LOGFILE
yes | apt-get install ssh wget sed python-software-properties git-core >> $OA_LOGFILE
yes | apt-get install nginx | tee -a $OA_LOGFILE

# Install bzr 2.6 beta 2 since bzr 2.5 has memory problems
echo -e "Adding newer bazaar 2.6 beta 2 - adding bzr repositories to apt"
yes | add-apt-repository ppa:bzr/beta >> $OA_LOGFILE
yes | apt-get update >> $OA_LOGFILE
yes | apt-get upgrade >> $OA_LOGFILE
yes | apt-get install bzr | tee -a $OA_LOGFILE

# Install latest PostgreSQL 9.3 or because it makes OpenERP 7 MUCH faster
echo -e "Installing PostgreSQL 9.3 and bazaar 2.6 beta 2"
echo -e "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
echo -e "Adding public keys for new postgresql repos:"
wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add - >> $OA_LOGFILE
yes | apt-get update >> $OA_LOGFILE
yes | apt-get upgrade >> $OA_LOGFILE
yes | apt-get remove postgresql-9.1 postgresql-9.2 >> $OA_LOGFILE # it is really important to remove the old config too!
rm /etc/postgresql/9.1 -R >> $OA_LOGFILE
rm /etc/postgresql/9.2 -R >> $OA_LOGFILE
yes | apt-get install postgresql-9.3 | tee -a $OA_LOGFILE
echo -e "\nWARNING: The default port for PostgreSQL 9.3 is 5433 instead of 5432 for 9.1: \
\nIf you want to make sure that there are absolutely no side effects change it to 9.1 default of 5432!\n"
service postgresql restart >> $OA_LOGFILE

# Add some services to init
echo "-----------------------------------" >> $OA_LOGFILE
#update-rc.d ssh defaults >> $OA_LOGFILE
update-rc.d postgresql defaults >> $OA_LOGFILE
update-rc.d nginx defaults >> $OA_LOGFILE

# Install Core support packages for OpenERP
echo -e "\nInstalling dependencies for OpenERP: PLEASE BE PATIENT\n"
yes | apt-get install graphviz ghostscript postgresql-client \
python-dateutil python-feedparser python-matplotlib \
python-ldap python-libxslt1 python-lxml python-mako \
python-openid python-psycopg2 python-pybabel python-pychart \
python-pydot python-pyparsing python-reportlab python-simplejson \
python-tz python-vatnumber python-vobject python-webdav \
python-werkzeug python-xlwt python-yaml python-imaging >> $OA_LOGFILE

# Install some interesting additional packages
echo -e "\nInstalling additional packages that may be benefitial for OpenERP: PLEASE BE PATIENT\n"
yes | apt-get install gcc python-dev mc bzr python-setuptools python-babel \
python-feedparser python-reportlab-accel python-zsi python-openssl \
python-egenix-mxdatetime python-jinja2 python-unittest2 python-mock \
python-docutils lptools make python-psutil python-paramiko poppler-utils \
python-pdftools python-networkx antiword >> $OA_LOGFILE

# Install dependencies for etherpad-light
yes | add-apt-repository ppa:chris-lea/node.js >> $OA_LOGFILE
yes | apt-get update  >> $OA_LOGFILE
yes | apt-get upgrade >> $OA_LOGFILE
yes | apt-get install nodejs gzip git-core curl python libssl-dev build-essential abiword python-software-properties >> $OA_LOGFILE
yes | apt-get update --fix-missing >> $OA_LOGFILE

# Install newer gdata client since ubuntu package is old
echo -e "\nInstalling gdata client 2.0.17 from google since the version in ubuntu 12.04 LTS is old\n"
wget http://gdata-python-client.googlecode.com/files/gdata-2.0.17.zip >> $OA_LOGFILE
unzip gdata-2.0.17.zip >> $OA_LOGFILE
rm -rf gdata-2.0.17.zip >> $OA_LOGFILE
cd gdata* >> $OA_LOGFILE
yes | python setup.py install >> $OA_LOGFILE

# Install newer pywebdav since ubuntu package is old https://bugs.launchpad.net/openobject-addons/+bug/1104559
echo -e "\nInstalling pywebdav 0.9.4 with pip newer or older version will not work in oe 7.0"
yes | apt-get install python-pip >> $OA_LOGFILE
yes | pip install pywebdav==0.9.4 >> $OA_LOGFILE
yes | pip install xlrd >> $OA_LOGFILE
yes | pip install xlutils >> $OA_LOGFILE

# Install wkhtmlto pdf for webkit report enginge
echo -e "\n Installing wkhtmltopdf 0.9.9 for the mako report engine (newer Versions seem to fail)"
echo -e "More Information can be found here: http://help.openerp.com/question/4724/how-to-configure-webkit-for-v7"
echo -e "Source Code: https://code.google.com/p/wkhtmltopdf/"
yes | apt-get install wkhtmltopdf >> $OA_LOGFILE

# CREATE LOGFILE PATH FOR OPENERP!!!
mkdir /var/log/openerp >> $OA_LOGFILE
chown root:root /var/log/openerp >> $OA_LOGFILE
chmod o=rx /var/log/openerp >> $OA_LOGFILE

# Install the support packages for AEROO REPORTS
echo -e "\nInstalling the dependencies for aeroo-reports: PLEASE BE PATIENT \n(-headless NOT needed: IS already in OO>=3)\n"
echo -e "http://www.alistek.com/wiki/index.php/Main_Page"
echo -e "https://launchpad.net/aeroo"
echo -e "https://code.launchpad.net/~kndati/aeroolib/trunk\n\n"
yes | apt-get install python-genshi python-mako python-openoffice python-uno python-pyhyphen python-xlwt unoconv\
    python-lxml libreoffice-core libreoffice-common libreoffice-base libreoffice-base-core libreoffice-draw \
    libreoffice-calc libreoffice-filter-binfilter libreoffice-filter-mobiledev libreoffice-writer libreoffice-impress\
    python-cupshelpers openoffice.org >> $OA_LOGFILE
bzr branch lp:aeroolib /opt/openerp/aeroolib >> $OA_LOGFILE
cd /opt/openerp/aeroolib/aeroolib >> $OA_LOGFILE
yes | python setup.py install >> $OA_LOGFILE
yes | python setup.py install >> $OA_LOGFILE
ln -s ${SCRIPTPATH}/aeroo-openoffice.init /etc/init.d/aeroo-openoffice
update-rc.d aeroo-openoffice defaults >> $OA_LOGFILE
service aeroo-openoffice stop >> $OA_LOGFILE
service aeroo-openoffice start >> $OA_LOGFILE
###TODO Überwachung für den OpenOffice Headless Server


# Install the support packages for the VNC Zimbra Connector
echo -e "\nInstalling the dependencies and for the VNC Zimbra Connector"
echo -e "ATTENTION: This connector is commerzial so if you use it make sure you pay for it!\n\n"
yes | apt-get install python-pip python-setuptools >> $OA_LOGFILE
yes | pip install --upgrade setuptools >> $OA_LOGFILE
yes | easy_install icalendar markdown smartypants >> $OA_LOGFILE
echo -e "You have to install the right components and the related zimlet on your zimbra mail server too!!!"
echo -e "On your Zimbra !!!8.0.5!!! Mailserver:"
echo -e "1.) wget http://packages.vnc.biz/zmpkg/bootstrap/zmpkg-installer-*.gz"
echo -e "2.) entpacken und installieren"
echo -e "3.) su - zimbra"
echo -e "4.) Use the new special apt: \\n zm-apt-get update; zm-apt-get update"
echo -e "5.) zm-apt-get install zcs-openerp-connector-pro"
echo -e "HINT1: zm-apt-cache search zcs"
echo -e "HINT2: do NOT use zcs-openerp-connector-pro-z8"

# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT ##### \n"