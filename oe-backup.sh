#!/bin/bash
# Autor: Michael Karrer
# Date: 08.01.2014
# Version: 1.3
# Description: This script will backup OpenERP 7.0 and all of it's related databases
#############

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTPATH=$(cd ${0%/*} && pwd -P)
echo -e "\n##### START SCRIPT:  ##### \n\n$SCRIPT\nIN PATH: $SCRIPTPATH"
echo -e "\nSYNTAX: oe-backup.sh {BACKUPTYPE full|dbonly} {STARTSERVICE nostart|start} [INSTANCEPATH e.g.: /opt/openerp/ope-7.0-32069]\n"

# SETUPPROMPT

if [ "$1" == "" ] ; then OA_BACKUPTYPE="full" ; else OA_BACKUPTYPE=`echo $1 | sed -e 's/\(.*\)/\L\1/'` ; fi           # Convert to lowercase
if [ "$2" == "" ] ; then OA_STARTSERVICE="start" ; else OA_STARTSERVICE=`echo $2 | sed -e 's/\(.*\)/\L\1/'` ; fi      # Convert to lowercase
if [ "$3" == "" ] ; then OA_INSTANCEPATH=$SCRIPTPATH; else OA_INSTANCEPATH=$3 ; fi
OA_OE_SERIES="7.0"
OA_BACKUPDIR="$OA_INSTANCEPATH/00-BACKUP/`date +%Y-%m-%d`"
# TODO add an UPDATE-LOG-file to the BACKUPPATH

# Checking the number and correctness of the arguments:
if ([[ $# -ge 2 ]]) && ([[ $OA_BACKUPTYPE == "full" ]] || [[ $OA_BACKUPTYPE == "dbonly" ]]) && ([[ $OA_STARTSERVICE == "start" ]] || [[ $OA_STARTSERVICE == "nostart" ]])
then
    echo -e ""
else
    echo -e ""
    echo -e "FEHLER: Bitte überprüfen sie Ihre Angaben!"
    echo -e "SCRIPT BEENDET!"
    echo -e ""
    exit 2
fi

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

# TODO TEST connection to db with this user - "EXIT 2" script if it fails

# Allow the user to check all arguments:
echo -e ""
echo -e "\$1 OpenERP INSTANCE PATH       : $OA_INSTANCEPATH"
echo -e "\$2 Type of backup              : $OA_BACKUPTYPE"
echo -e "\$3 Start service after backup  : $OA_STARTSERVICE"
echo -e "   OpenERP INSTANCE NAME       :  $OA_INSTANCENAME"
echo -e "   OpenERP INSTANCE USER       :  $OA_DBUSER"
echo -e "   OpenERP VERSION/SERIES      :  $OA_OE_SERIES"
echo -e "   Backup Directory            :  $OA_BACKUPDIR"
echo -e ""
echo -e "WARNING THE SERVICE WILL BE STOPPED DURING THE BACKUP"
echo -e ""

/bin/echo -e "Would you like to perform the BACKUP for $OA_INSTANCEPATH? ( Y/N ) :"
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

# Create the Backup Directory
if mkdir $OA_BACKUPDIR
then
    echo -e "Backup Directory $OA_BACKUPDIR created"
else
    echo -e "ERROR: Can not create the Backup Directory "
    echo -e "EXITITNG SCRIPT"
    exit 1
fi

# STOP THE SERVICE
echo -e "Stopping the Service openerp-${OA_INSTANCENAME}"
service openerp-${OA_INSTANCENAME} stop
sleep 5s
if ps ax | grep -v grep | grep openerp-${OA_INSTANCENAME} > /dev/null
then
    echo -e "ERROR Can not stop service openerp-${OA_INSTANCENAME}"
    echo -e "EXITING SCRIPT"
    exit 1
else
    echo -e "Service stopped"
fi

# CREATE THE BACKUP (DATABASE AND FILES)
echo -e "STARTING BACKUP - PLEASE BE PATIENT!"

# File backup
if [ $OA_BACKUPTYPE == "full" ]
then
    # copy everything except the 00-BACKUP dir
    # archive (=recursive links-as-symlinks preserve-permissions preserver-owner preserver-group) quiet preserver-Excutability
    if rsync -aqE --exclude 00-BACKUP $OA_INSTANCEPATH $OA_BACKUPDIR
    then
        echo -e "\n All files are backuped to $OA_BACKUPDIR"
    else
        echo -e "\n ERROR could not backup files - EXITING SCRIPT WITH ERROR"
        exit 1
    fi
fi

# Database Backup
echo -e ""
if ${SCRIPTPATH}/pg_backup.sh
then
    echo -e "\n Database Backup done"
else
    echo -e "\n ERROR Database Backup faild - EXITING SCRIPT WITH ERROR"
    exit 1
fi


# START THE SERVICE
if [ $OA_STARTSERVICE != "nostart" ]
then
    echo -e "Starting the Service openerp-${OA_INSTANCENAME}"
    service openerp-${OA_INSTANCENAME} start
    sleep 5s
    if ps ax | grep -v grep | grep openerp-${OA_INSTANCENAME} > /dev/null
    then
        echo -e "Service started"
    else
        echo -e "ERROR Can not start service openerp-${OA_INSTANCENAME}"
        echo -e "EXITING SCRIPT"
        exit 1
    fi
fi

# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT in $SCRIPTPATH ##### \n"

