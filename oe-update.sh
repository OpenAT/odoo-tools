#!/bin/bash
# Autor: Michael Karrer
# Date: 08.01.2014
# Version: 1.3
# Description: This script will update an OpenERP 7.0 instance
#############

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTPATH=$(cd ${0%/*} && pwd -P)
echo -e "\n##### START SCRIPT:  ##### \n\n$SCRIPT\nIN PATH: $SCRIPTPATH"
echo -e "\nSYNTAX: oe-update_custom_addons.sh {INSTANCEPATH e.g.: /opt/openerp/ope-7.0-32069} "

# SETUPPROMPT
if [ "$1" == "" ]
then
    OA_INSTANCEPATH=$SCRIPTPATH
else
    OA_INSTANCEPATH=$1
fi
OA_OE_SERIES="7.0"



# Check if the path is correct and we can "cd" to this directory
if ! cd $OA_INSTANCEPATH ; then
    echo -e "ERROR Can not change directory to $OA_INSTANCEPATH"
    echo -e "SCRIPT BEENDET!"
    echo -e ""
    exit 2
fi

# Since the path seems to be correct we grab the user of the directory for later
OA_DBUSER=`ls -ld $OA_INSTANCEPATH/custom-addons | awk '{print $3}'`
OA_INSTANCENAME=`basename "${OA_INSTANCEPATH}"`

# TODO add an UPDATE LOG file to the INSTANCEPATH

# Allow the user to check all arguments:
echo -e ""
echo -e "\$1 OpenERP INSTANCE PATH    : $OA_INSTANCEPATH"
echo -e "   OpenERP INSTANCE NAME    :  $OA_INSTANCENAME"
echo -e "   OpenERP INSTANCE USER    :  $OA_DBUSER"
echo -e "   OpenERP VERSION/SERIES   :  $OA_OE_SERIES"
echo -e ""
echo -e "WARNING: THE SERVICE WILL BE STOPPED DURING THE UPDATE"
echo -e ""

/bin/echo -e "Would you like to perform the UPDATE for $OA_INSTANCEPATH? ( Y/N ) :"
read answer
while [ "$answer" != "y" ] && [ "$answer" != "Y" ]
do
    echo "Please enter Y (Yes) or N (No)"
    read answer
    if [ "$answer" == "n" ] || [ "$answer" == "N" ]
    then
        echo "SCRIPT STOPPED BY USER"
        exit 1
    fi
done


# STOP THE SERVICE
echo -e "Stopping the Service openerp-${OA_INSTANCENAME}"
service openerp-${OA_INSTANCENAME} stop
sleep 10s
if ps ax | grep -v grep | grep openerp-${OA_INSTANCENAME} > /dev/null
then
    echo -e "ERROR Can not stop service openerp-${OA_INSTANCENAME}"
    echo -e "EXITING SCRIPT"
    exit 4
else
    echo -e "Service stopped"
fi

# CREATE A FULL BACKUP (DATABASE AND FILES)
echo -e "STARTING BACKUP - PLEASE BE PATIENT!!!"
cd $SCRIPTPATH
if $SCRIPTPATH/oe-backup.sh full nostart $OA_INSTANCEPATH ; then
    echo -e "BACKUP DONE!"
else
    echo -e " ERROR Backup failed! - EXITING SCRIPT"
    exit 5
fi

echo -e "\nPlease check the backup-log above carefully! \nDo you still want to perform the update for $OA_INSTANCEPATH? ( Y/N ) :"
read answer
echo -e ""
if [ "$answer" != "y" ] && [ "$answer" != "Y" ]
then
    echo -e "SCRIPT STOPPED"
    exit 3
fi

# UPDATE THE INSTANCE
if cd $OA_INSTANCEPATH/server ; then bzr pull; else echo -e "ERROR can not update $OA_INSTANCEPATH/server" && exit 6; fi
if cd $OA_INSTANCEPATH/addons ; then bzr pull; else echo -e "ERROR can not update $OA_INSTANCEPATH/addons" && exit 7; fi
if cd $OA_INSTANCEPATH/web    ; then bzr pull; else echo -e "ERROR can not update $OA_INSTANCEPATH/web" && exit 8; fi
if cd $SCRIPTPATH             ; then $SCRIPTPATH/oe-update_custom_addons.sh full $OA_INSTANCEPATH; else echo -e "ERROR can not update $OA_INSTANCEPATH/custom-addons" && exit 9; fi


# START THE SERVICE
echo -e "Starting the Service openerp-${OA_INSTANCENAME}"
service openerp-${OA_INSTANCENAME} start
sleep 10s
if ps ax | grep -v grep | grep openerp-${OA_INSTANCENAME} > /dev/null
then
    echo -e "Service started"
    echo -e "Service started"
else
    echo -e "ERROR Can not start service openerp-${OA_INSTANCENAME}"
    echo -e "EXITING SCRIPT"
    exit 10
fi

# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT ##### \n"
