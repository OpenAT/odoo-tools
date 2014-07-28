#!/bin/bash
# Autor: Michael Karrer
# Date: 25.08.2013
# Version: 1.3
# Description: This is the installation Script for a new OpenERP 7.0 stable or Saas installation
# It will install all the dependencies, configure user and folder, add a new nginx config file
# and download the desired version from the openat bazaar branch for Ubuntu 10.04.12 LTS
# usage: openerp-setup-sh [7.0|saas1] instancename password baseport preparesystem
#############


# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTPATH=$(cd ${0%/*} && pwd -P)
echo -e "\n##### START SCRIPT:  ##### \n\n$SCRIPT\nIN PATH: $SCRIPTPATH"
echo -e "\nSYNTAX: {OpenERP Series [7.0|saas1]} {OpenERP Admin Password} {Company Number (e.g.: OPE)} {Domain Name}}\n"

# SETUPPROMPT
OA_OE_SERIES=$1
OA_OE_ADMINPASSWORD=$2
OA_CNUMBER=$3
# Convert to Lowercase
OA_CNUMBER=`echo ${OA_CNUMBER} | sed -e 's/\(.*\)/\L\1/'`
OA_SERVER_DNS_NAME=$4

# Checking the number and correctness of the arguments:
if [ $# -ne 4 ]
then
    echo -e "\nFEHLER: Bitte überprüfen sie Ihre Angaben!"
    echo -e "SYNTAX: {OpenERP Series [7.0|saas1]} {OpenERP Admin Password} {Company Number (e.g.: OPE)} {Domain Name}}"
    echo -e "SCRIPT BEENDET!"
    exit 2
fi

if [ "$OA_OE_SERIES" != "7.0" ]
then
    echo -e "SORRY currently only 7.0 Series is supported."
fi

# set the baseport counter to avoid the same port for instances on this server
if [ -f ${SCRIPTPATH}/OA_BASEPORT.counter ]
then
    echo -e "File ${SCRIPTPATH}/OA_BASEPORT.counter exists"
else
    if touch ${SCRIPTPATH}/OA_BASEPORT.counter;
    then
        echo -e "40" > ${SCRIPTPATH}/OA_BASEPORT.counter;
    else
        echo -e "\nERROR Could not create file ${SCRIPTPATH}/OA_BASEPORT.counter - EXITING SCRIPT \n"
        exit 2
    fi
fi
typeset -i OA_BASEPORT
OA_BASEPORT=`cat ${SCRIPTPATH}/OA_BASEPORT.counter`
OA_BASEPORT=$OA_BASEPORT+1
echo $OA_BASEPORT > ${SCRIPTPATH}/OA_BASEPORT.counter

OA_DBUSER="${OA_CNUMBER}_${OA_BASEPORT}069"
OA_DBPW=`tr -cd \#_[:alnum:] < /dev/urandom |  fold -w 8 | head -1`
OA_BASEDIR="/opt/openerp"
OA_INSTANCENAME="${OA_CNUMBER}-${OA_OE_SERIES}-${OA_BASEPORT}069"
OA_INSTANCEPATH="${OA_BASEDIR}/${OA_INSTANCENAME}"
OA_LOGFILEPATH="/var/log/openerp/${OA_INSTANCENAME}"
OA_SETUPLOG="${SCRIPTPATH}/setup-${OA_INSTANCENAME}.log"
OA_ETHERPADKEY=`tr -cd \#_[:alnum:] < /dev/urandom |  fold -w 16 | head -1`


# Allow the user to check all arguments:
echo -e ""
echo -e "\$1 OpenERP Series: [7.0|saas]    :  $OA_OE_SERIES" | tee -a $OA_SETUPLOG
echo -e "\$2 OpenERP Admin User Password   :  $OA_OE_ADMINPASSWORD" | tee -a $OA_SETUPLOG
echo -e "\$3 Company Number (e.g.: fbg)    :  $OA_CNUMBER" | tee -a $OA_SETUPLOG
echo -e "\$4 Domain Name                   :  $OA_SERVER_DNS_NAME" | tee -a $OA_SETUPLOG
echo -e ""
echo -e "OpenERP Baseport                 :  $OA_BASEPORT" | tee -a $OA_SETUPLOG
echo -e "OpenERP Database User Name       :  $OA_DBUSER" | tee -a $OA_SETUPLOG
echo -e "OpenERP Database User Password   :  $OA_DBPW" | tee -a $OA_SETUPLOG
echo -e "OpenERP LINUX User = DB-User     :  $OA_DBUSER" | tee -a $OA_SETUPLOG
echo -e "OpenERP Base Directory           :  $OA_BASEDIR" | tee -a $OA_SETUPLOG
echo -e "OpenERP Instance Name            :  $OA_INSTANCENAME" | tee -a $OA_SETUPLOG
echo -e "OpenERP Instance Directory       :  $OA_INSTANCEPATH" | tee -a $OA_SETUPLOG
echo -e "OpenERP Logfile Directory        :  $OA_LOGFILEPATH" | tee -a $OA_SETUPLOG
echo -e "OpenERP Setuplog File            :  $OA_SETUPLOG" | tee -a $OA_SETUPLOG
echo -e "Etherpad SESSION KEY             :  $OA_ETHERPADKEY" | tee -a $OA_SETUPLOG
echo -e ""


/bin/echo -e "Would you like to setup a new OpenERP instance with this settings? ( Y/N ) :"
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

### STEP 2: PREPARE THE NEW INSTANCE
if cd $OA_BASEDIR ; then
    echo -e "Changed path to $OA_BASEDIR"
else
    echo -e "Could not change to directory $OA_BASEDIR."
    echo -e "If this is a new install you need to run openerp-prepare_system.sh first."
    echo -e "EXIT SCRIPT"
    exit 1
fi

# CREATE the linux user (and a group with the same name = standard in ubuntu)
echo -e "Create the Linux user $OA_DBUSER and the same group with home directory and bash shell" | tee -a $OA_SETUPLOG
useradd -m -s /bin/bash $OA_DBUSER | tee -a $OA_SETUPLOG

# CREATE the directories
echo -e "Creating Instance Directories"
mkdir $OA_INSTANCEPATH | tee -a $OA_SETUPLOG
mkdir $OA_INSTANCEPATH/custom-addons | tee -a $OA_SETUPLOG
mkdir $OA_INSTANCEPATH/custom-addons-loaded | tee -a $OA_SETUPLOG
mkdir $OA_INSTANCEPATH/00-BACKUP | tee -a $OA_SETUPLOG

# SET correct directory owner
echo -e "ALready set the right user and group for $OA_INSTANCEPATH and its files so that all later scripts will work"
chown $OA_DBUSER:$OA_DBUSER $OA_INSTANCEPATH -Rf

# LOAD all custom-addons (load first because faster as the server addons and web)
if cd $SCRIPTPATH
then
    yes | $SCRIPTPATH/oe-update_custom_addons.sh full $OA_INSTANCEPATH
else
    echo "ERROR Could not change to $SCRIPTPATH - EXIT SCRIPT"
    exit 2
fi

# bzr branch server, addons, web and custom-addons
echo -e "Get the latest OCB branches from launchpad" | tee -a $OA_SETUPLOG
echo -e "WARNING: Switched to OpenERP 7.0 OCB branches since most of the bugs are fixed there already!" | tee -a $OA_SETUPLOG
bzr branch lp:~ocb/ocb-server/7.0 $OA_INSTANCEPATH/server
bzr branch lp:~ocb/ocb-addons/7.0 $OA_INSTANCEPATH/addons
bzr branch lp:~ocb/ocb-web/7.0    $OA_INSTANCEPATH/web

# CREATE the db user
# ACHTUNG vorher checken ob postgresql läuft und vor allem ob nur eine Version läuft sonst config in /etc löschen!
echo -e "Create postgresql role $OA_DBUSER"
sudo su - postgres -c \
    'psql -a -e -c "CREATE ROLE '${OA_DBUSER}' WITH NOSUPERUSER CREATEDB LOGIN PASSWORD '\'${OA_DBPW}\''"' | tee -a $OA_SETUPLOG


# Create the OpenERP Server Config File
# (Writing a new Server.conf file with sed (http://de.wikipedia.org/wiki/Sed_(Unix))
echo -e "Write the OpenERP Server Config File ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.conf" | tee -a $OA_SETUPLOG
/bin/sed '{
    s,OA_BASEPORT,'"$OA_BASEPORT"',g
    s,OA_OE_ADMINPASSWORD,'"$OA_OE_ADMINPASSWORD"',g
    s,OA_DBUSER,'"$OA_DBUSER"',g
    s,OA_DBPW,'"$OA_DBPW"',g
    s,OA_INSTANCEPATH,'"$OA_INSTANCEPATH"',g
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_LOGFILEPATH,'"$OA_LOGFILEPATH"',g
        }' ${SCRIPTPATH}/openerp-7.0.conf > ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.conf | tee -a $OA_SETUPLOG
chmod o=r ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.conf | tee -a $OA_SETUPLOG
ln -s ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.conf /etc/openerp-${OA_INSTANCENAME}.conf | tee -a $OA_SETUPLOG


# create the startup script and chkconfig on ;) - so add it to the right runlevel(s)
echo -e "Write the OpenERP Server init file ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.init" | tee -a $OA_SETUPLOG
/bin/sed '{
    s,OA_DBUSER,'"$OA_DBUSER"',g
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_INSTANCEPATH,'"$OA_INSTANCEPATH"',g
        }' ${SCRIPTPATH}/openerp-7.0.init > ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.init | tee -a $OA_SETUPLOG
chmod ugo=+r+x ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.init | tee -a $OA_SETUPLOG
ln -s ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}.init /etc/init.d/openerp-${OA_INSTANCENAME} | tee -a $OA_SETUPLOG
update-rc.d openerp-${OA_INSTANCENAME} defaults | tee -a $OA_SETUPLOG


# Install etherpad-light
echo -e "Installation of etherpad-lite at 127.0.0.1:${OA_BASEPORT}901"
if cd ${OA_INSTANCEPATH}
then
    # get etherpad from github
    yes | git clone git://github.com/ether/etherpad-lite.git
    # Create the database (utf8)
    echo -e "Create postgresql Database for etherpad lite: etherpad_${OA_BASEPORT}901"
    sudo su - postgres -c \
        'psql -a -e -c "CREATE DATABASE etherpad_'${OA_BASEPORT}'901 WITH OWNER '${OA_DBUSER}' ENCODING '\'UTF8\''" ' | tee -a $OA_SETUPLOG
    # etherpad-lite config file
    /bin/sed '{
    s,OA_BASEPORT,'"$OA_BASEPORT"',g
    s,OA_OE_ADMINPASSWORD,'"$OA_OE_ADMINPASSWORD"',g
    s,OA_DBUSER,'"$OA_DBUSER"',g
    s,OA_DBPW,'"$OA_DBPW"',g
    s,OA_INSTANCEPATH,'"$OA_INSTANCEPATH"',g
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_LOGFILEPATH,'"$OA_LOGFILEPATH"',g
    s,OA_ETHERPADKEY,'"$OA_ETHERPADKEY"',g
        }' ${SCRIPTPATH}/settings.json.template > ${OA_INSTANCEPATH}/etherpad-lite/settings.json | tee -a $OA_SETUPLOG
    # Create the init file (wich creates the log files)
    /bin/sed '{
    s,OA_BASEPORT,'"$OA_BASEPORT"',g
    s,OA_DBUSER,'"$OA_DBUSER"',g
    s,OA_INSTANCEPATH,'"$OA_INSTANCEPATH"',g
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_LOGFILEPATH,'"$OA_LOGFILEPATH"',g
        }' ${SCRIPTPATH}/etherpad.init > ${OA_INSTANCEPATH}/etherpad-$OA_INSTANCENAME.init | tee -a $OA_SETUPLOG
    chmod ugo=+r+x ${OA_INSTANCEPATH}/etherpad-${OA_INSTANCENAME}.init | tee -a $OA_SETUPLOG
    ln -s ${OA_INSTANCEPATH}/etherpad-${OA_INSTANCENAME}.init /etc/init.d/etherpad-${OA_INSTANCENAME} | tee -a $OA_SETUPLOG
    update-rc.d etherpad-${OA_INSTANCENAME} defaults | tee -a $OA_SETUPLOG
    # change to the correct rights
    chown $OA_DBUSER:$OA_DBUSER $OA_INSTANCEPATH -Rf
    # start the service
    service etherpad-${OA_INSTANCENAME} start
else
    echo "ERROR Could not change to $OA_INSTANCEPATH for etherpad installation - EXIT SCRIPT"
    exit 2
fi


# prepare the backup and update scripts for maintainance
echo -e "Write the OpenERP Backup-Postgres-Config-File ${OA_INSTANCEPATH}/pg_backup.config" | tee -a $OA_SETUPLOG
/bin/sed '{
    s,OA_DBUSER,'"$OA_DBUSER"',g
    s,OA_DBPW,'"$OA_DBPW"',g
    s,OA_INSTANCEPATH,'"$OA_INSTANCEPATH"',g
        }' ${SCRIPTPATH}/pg_backup.config > ${OA_INSTANCEPATH}/pg_backup.config | tee -a $OA_SETUPLOG
ln -s $SCRIPTPATH/oe-update* ${OA_INSTANCEPATH}/.
ln -s $SCRIPTPATH/oe-backup.sh ${OA_INSTANCEPATH}/.
ln -s $SCRIPTPATH/pg_backup.sh ${OA_INSTANCEPATH}/.
ln -s $SCRIPTPATH/pg_backup_rotated.sh ${OA_INSTANCEPATH}/.
echo -e "#"'!'"/bin/bash\n\ncd ${OA_INSTANCEPATH}\n${OA_INSTANCEPATH}/pg_backup_rotated.sh" > /etc/cron.daily/openerp-${OA_INSTANCENAME}.cronjob
chmod ugo=rx /etc/cron.daily/openerp-${OA_INSTANCENAME}.cronjob
ln -s /etc/cron.daily/openerp-${OA_INSTANCENAME}.cronjob ${OA_INSTANCEPATH}/.


# TODO add postgresql every point in time backup with local barman server


# create the logfile path and the logrotate config file
# nginx logrotate file not needed since it rotates all *.log files by default
echo -e "Create the logfile directory: $OA_LOGFILEPATH" | tee -a $OA_SETUPLOG
mkdir $OA_LOGFILEPATH | tee -a $OA_SETUPLOG
chown $OA_DBUSER:$OA_DBUSER $OA_LOGFILEPATH -Rf | tee -a $OA_SETUPLOG
/bin/sed '{
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_LOGFILEPATH,'"$OA_LOGFILEPATH"',g
        }' ${SCRIPTPATH}/openerp-7.0-logrotate.conf > ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-logrotate.conf | tee -a $OA_SETUPLOG
chmod o=r ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-logrotate.conf | tee -a $OA_SETUPLOG
ln -s ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-logrotate.conf /etc/logrotate.d/openerp-${OA_INSTANCENAME}-logrotate.conf | tee -a $OA_SETUPLOG
ln -s /var/log/nginx/${OA_INSTANCENAME}.log ${OA_LOGFILEPATH}/${OA_INSTANCENAME}-nginx.log
ln -s ${OA_LOGFILEPATH} ${OA_INSTANCEPATH}/log | tee -a $OA_SETUPLOG

# TODO Configure some sort of watchdog that will monitor the process(es) (python, nginx, openoffice, etherpad, postgresql, ...)


### STEP 3: PREPARE NGINX
# create the nginx config file
echo -e "Write the NGINX config file ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-nginx.conf" | tee -a $OA_SETUPLOG
/bin/sed '{
    s,OA_BASEPORT,'"$OA_BASEPORT"',g
    s,OA_INSTANCENAME,'"$OA_INSTANCENAME"',g
    s,OA_SERVER_DNS_NAME,'"$OA_SERVER_DNS_NAME"',g
        }' ${SCRIPTPATH}/openerp-7.0-nginx.conf > ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-nginx.conf | tee -a $OA_SETUPLOG
chmod o=r ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-nginx.conf | tee -a $OA_SETUPLOG
ln -s ${OA_INSTANCEPATH}/openerp-${OA_INSTANCENAME}-nginx.conf /etc/nginx/sites-enabled/openerp-${OA_INSTANCENAME}-${OA_SERVER_DNS_NAME}-nginx.conf | tee -a $OA_SETUPLOG
# reload nginx
service nginx restart


### STEP 4: START THE OPENERP INSTANCE
service openerp-${OA_INSTANCENAME} start


### STEP 5: Cleanup and End of Script

# Move the setup log file to the instancepath
mv $OA_SETUPLOG ${OA_INSTANCEPATH}

# echo the etherpad api key
echo -e "To use etherpad in your Openerp instance use"
echo -e "Address: ${OA_SERVER_DNS_NAME}/pad \nAPI Key:"
echo -e "$OA_INSTANCEPATH/etherpad-lite/APIKEY.txt"
echo -e "You can set this for every company in the settings menu of the company\n"
echo -e "WARNING: The first start of etherpad-lite takes a loooong time so please be patient"
echo -e "WARNING: There is currently a bug in the timeslider of etherpad-lite \nplease look at: https://github.com/fzimmermann89/etherpad-lite/commit/7f73bd2100b6b678a92e22425f3673b9fd9d35a7 \nif it is not working for you!"

echo -e "\nPlease reboot your system after 5 to 10 minutes after this script has finished!"


# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT ##### \n"
