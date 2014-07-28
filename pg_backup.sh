#!/bin/bash

###########################
####### LOAD CONFIG #######
###########################

while [ $# -gt 0 ]; do
        case $1 in
                -c)
                        if [ -r "$2" ]; then
                                source "$2"
                                shift 2
                        else
                                ${ECHO} "Ureadable config file \"$2\""
                                exit 1
                        fi
                        ;;
                *)
                        ${ECHO} "Unknown Option \"$1\""
                        exit 2
                        ;;
        esac
done

if [ $# = 0 ]; then
        # Absolute path to this script, e.g. /home/user/bin/foo.sh
        SCRIPT=$(readlink -f "$0")

        # Absolute path this script is in, thus /home/user/bin
        SCRIPTPATH=$(cd ${0%/*} && pwd -P)  #SCRIPTPATH=$(dirname "$SCRIPT") would be mikes version but we use the original one in this script:
        source $SCRIPTPATH/pg_backup.config

        echo -e "\n##### START SCRIPT:  ##### \n$SCRIPT\nIN PATH \n$SCRIPTPATH"
fi;



###########################
#### PRE-BACKUP CHECKS ####
###########################

# Make sure we're running as the required backup user
if [ "$BACKUP_USER" != "" -a "$(id -un)" != "$BACKUP_USER" ]; then
	echo "This script must be run as $BACKUP_USER. Exiting."
	exit 1;
fi;


###########################
### INITIALISE DEFAULTS ###
###########################

if [ ! $HOSTNAME ]; then
	HOSTNAME="localhost"
fi;

if [ ! $USERNAME ]; then
	USERNAME="postgres"
fi;


###########################
#### START THE BACKUPS ####
###########################


FINAL_BACKUP_DIR=$BACKUP_DIR"`date +%Y-%m-%d`/"

echo "Making backup directory in $FINAL_BACKUP_DIR"

if cd $FINAL_BACKUP_DIR
then
    echo "Backup directory $FINAL_BACKUP_DIR already exists."
else
    if ! mkdir -p $FINAL_BACKUP_DIR; then
        echo "Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!"
        exit 1;
    fi;
fi;

###########################
### SCHEMA-ONLY BACKUPS ###
###########################

for SCHEMA_ONLY_DB in ${SCHEMA_ONLY_LIST//,/ }
do
	SCHEMA_ONLY_CLAUSE="$SCHEMA_ONLY_CLAUSE or datname ~ '$SCHEMA_ONLY_DB'"
done

SCHEMA_ONLY_QUERY="select datname from pg_database where false $SCHEMA_ONLY_CLAUSE order by datname;"

echo -e "\nPerforming schema-only backups"
echo -e "--------------------------------------------\n"

SCHEMA_ONLY_DB_LIST=`psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$SCHEMA_ONLY_QUERY" postgres`

echo -e "The following databases were matched for schema-only backup:\n${SCHEMA_ONLY_DB_LIST}\n"

for DATABASE in $SCHEMA_ONLY_DB_LIST
do
	echo -e "\nSchema-only backup of $DATABASE"

	if ! pg_dump -Fp -s -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" | gzip > $FINAL_BACKUP_DIR"$DATABASE"_SCHEMA.sql.gz.in_progress; then
		echo -e "ERROR Failed to backup database schema of $DATABASE"
	else
		mv $FINAL_BACKUP_DIR"$DATABASE"_SCHEMA.sql.gz.in_progress $FINAL_BACKUP_DIR"$DATABASE"_SCHEMA.sql.gz
	fi
done


###########################
###### FULL BACKUPS #######
###########################

for SCHEMA_ONLY_DB in ${SCHEMA_ONLY_LIST//,/ }
do
	EXCLUDE_SCHEMA_ONLY_CLAUSE="$EXCLUDE_SCHEMA_ONLY_CLAUSE and datname !~ '$SCHEMA_ONLY_DB'"
done

FULL_BACKUP_QUERY="select datname from pg_database where not datistemplate and datallowconn $EXCLUDE_SCHEMA_ONLY_CLAUSE order by datname;"

echo -e "\nPerforming full backups"
echo -e "--------------------------------------------\n"

for DATABASE in `psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$FULL_BACKUP_QUERY" postgres`
do
	if [ $ENABLE_PLAIN_BACKUPS = "yes" ]
	then
		echo -e "\nPlain backup of $DATABASE"

		if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" -f $FINAL_BACKUP_DIR"$DATABASE".plain.sql.in_progress; then
			echo -e "ERROR Failed to backup database plain backup of $DATABASE"
			rm $FINAL_BACKUP_DIR"$DATABASE".plain.sql.in_progress
		else
	        mv $FINAL_BACKUP_DIR"$DATABASE".plain.sql.in_progress $FINAL_BACKUP_DIR"$DATABASE".plain.sql
			yes | gzip $FINAL_BACKUP_DIR"$DATABASE".plain.sql
		fi
	fi

	if [ $ENABLE_CUSTOM_BACKUPS = "yes" ]
	then
		echo -e "\nCustom backup of $DATABASE"

		if ! pg_dump -Fc -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" -f $FINAL_BACKUP_DIR"$DATABASE".custom.in_progress; then
			echo -e "ERROR Failed to backup database custom backup of $DATABASE"
			rm $FINAL_BACKUP_DIR"$DATABASE".custom.in_progress
		else
			mv $FINAL_BACKUP_DIR"$DATABASE".custom.in_progress $FINAL_BACKUP_DIR"$DATABASE".custom
			yes | gzip $FINAL_BACKUP_DIR"$DATABASE".custom
		fi
	fi

done


# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT in $SCRIPTPATH ##### \n"