#!/bin/bash
# Autor: Michael Karrer
# Date: 08.01.2014
# Version: 1.3
# Description: This script will load or update all custom-addons for a given OpenERP 7.0 instance
#############

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
#SCRIPTPATH=$(dirname "$SCRIPT")
SCRIPTPATH=$(cd ${0%/*} && pwd -P)
echo -e "\n##### START SCRIPT:  ##### \n\n$SCRIPT\nIN PATH: $SCRIPTPATH"
echo -e "\nSYNTAX: oe-update_custom_addons.sh {full|loadnew|mergesources} [INSTANCEPATH e.g.: /opt/openerp/ope-7.0-32069] \n"


# SETUPPROMPT
OA_OE_SERIES="7.0"

# Updatetype
if [ "$1" == "" ] ; then OA_UPDATETYPE="full" ; else OA_UPDATETYPE=$1 ;fi
if [ $OA_UPDATETYPE != "full" ] && [ $OA_UPDATETYPE != "loadnew" ] && [ $OA_UPDATETYPE != "mergesources" ]
then
    echo -e "\nERROR Wrong syntax! EXITING SCRIPT"
    echo -e "SYNTAX: oe-update_custom_addons.sh {full|loadnew|mergesources} [INSTANCEPATH e.g.: /opt/openerp/ope-7.0-32069] \n"
    exit 2
fi


# Instancepath
if [ "$2" == "" ]
then
    OA_INSTANCEPATH=$SCRIPTPATH
else
    OA_INSTANCEPATH=$2
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

# Allow the user to check all arguments:
echo -e ""
echo -e "\$1 OpenERP UPDATETYPE       :  $OA_UPDATETYPE"
echo -e "\$2 OpenERP INSTANCE PATH    :  $OA_INSTANCEPATH"
echo -e "   OpenERP INSTANCE USER    :  $OA_DBUSER"
echo -e "   OpenERP VERSION / SERIES :  $OA_OE_SERIES"
echo -e ""
/bin/echo -e "Would you like to update (and/or load new) custom-addons for $OA_INSTANCEPATH? ( Y/N ) :\n"
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


# TODO ADD an "DEVELOPPER UPDATE MODE ;) to really merge the original baranches with our copys see first line "then bzr merge lp:aeroo;" as an example"
if [ $OA_UPDATETYPE == "mergesources" ] ;
then
    if cd $OA_INSTANCEPATH/custom-addons/aeroo            >/dev/null 2>&1 ; then bzr merge lp:~kndati/aeroo/openerp7    ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/aeroo DOES NOT EXIST!" ; fi
    if cd $OA_INSTANCEPATH/custom-addons/elico            >/dev/null 2>&1 ; then bzr merge lp:~openerp-community/openobject-addons/elico-7.0    ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/aeroo DOES NOT EXIST!" ; fi
    if cd $OA_INSTANCEPATH/custom-addons/bhc              >/dev/null 2>&1 ; then bzr merge lp:~bhc-team/bhc/7.0         ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/bhc DOES NOT EXIST!"   ; fi
    if cd $OA_INSTANCEPATH/custom-addons/therp-fts        >/dev/null 2>&1 ; then bzr merge lp:openobject-fts/7.0        ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/therp-fts DOES NOT EXIST!"; fi
    if cd $OA_INSTANCEPATH/custom-addons/web-addons       >/dev/null 2>&1 ; then bzr merge lp:web-addons/7.0            ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/web-addons DOES NOT EXIST!"; fi
    if cd $OA_INSTANCEPATH/custom-addons/server-env-tools >/dev/null 2>&1 ; then bzr merge lp:server-env-tools/7.0               ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/server-env-tools DOES NOT EXIST!"; fi
    if cd $OA_INSTANCEPATH/custom-addons/openerp-india    >/dev/null 2>&1 ; then bzr merge lp:~openerp-india/openerp-india/7.0   ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/openerp-india DOES NOT EXIST!"; fi
    if cd $OA_INSTANCEPATH/custom-addons/julius           >/dev/null 2>&1 ; then bzr merge lp:julius-openobject-addons/7.0       ; else echo "MERGE FAILED: FOLDER $OA_INSTANCEPATH/custom-addons/julius DOES NOT EXIST!"; fi


else
    # LOAD / UPDATE Custom Addons
    if cd $OA_INSTANCEPATH/custom-addons/openat        >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/openat_7.0         $OA_INSTANCEPATH/custom-addons/openat; fi
    if cd $OA_INSTANCEPATH/custom-addons/camadeus      >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/camadeus_7.0       $OA_INSTANCEPATH/custom-addons/camadeus; fi
    #
    if cd $OA_INSTANCEPATH/custom-addons/aeroo            >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/aeroo_7.0            $OA_INSTANCEPATH/custom-addons/aeroo; fi
    if cd $OA_INSTANCEPATH/custom-addons/elico            >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/elico_7.0            $OA_INSTANCEPATH/custom-addons/elico; fi
    if cd $OA_INSTANCEPATH/custom-addons/bhc              >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/bhc_7.0              $OA_INSTANCEPATH/custom-addons/bhc; fi
    if cd $OA_INSTANCEPATH/custom-addons/therp-fts        >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/therp-fts_7.0        $OA_INSTANCEPATH/custom-addons/therp-fts; fi
    if cd $OA_INSTANCEPATH/custom-addons/web-addons       >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/web-addons_7.0       $OA_INSTANCEPATH/custom-addons/web-addons; fi
    if cd $OA_INSTANCEPATH/custom-addons/server-env-tools >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/server-env-tools_7.0 $OA_INSTANCEPATH/custom-addons/server-env-tools; fi
    if cd $OA_INSTANCEPATH/custom-addons/openerp-india    >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/openerp-india_7.0    $OA_INSTANCEPATH/custom-addons/openerp-india; fi
    if cd $OA_INSTANCEPATH/custom-addons/julius           >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/julius_7.0           $OA_INSTANCEPATH/custom-addons/julius; fi
    #
    if cd $OA_INSTANCEPATH/custom-addons/vnc           >/dev/null 2>&1 ; then bzr pull; elif [ $OA_UPDATETYPE == "full" ] ; then bzr branch lp:~oe-at-team/oe-at/vnc_7.0            $OA_INSTANCEPATH/custom-addons/vnc; fi


    # Remove depricated Addons
    if cd $OA_INSTANCEPATH/custom-addons-loaded/openat_customization_css >/dev/null 2>&1 ; then rm $OA_INSTANCEPATH/custom-addons-loaded/openat_customization_css; fi
    if cd $OA_INSTANCEPATH/custom-addons/grap >/dev/null 2>&1 ; then echo "WARNING $OA_INSTANCEPATH/custom-addons/grap is DEPRICATED please remove it"; fi
    if cd $OA_INSTANCEPATH/custom-addons/vaab >/dev/null 2>&1 ; then echo "WARNING $OA_INSTANCEPATH/custom-addons/vaab is DEPRICATED please remove it"; fi


    # LINK THE DEFAULT SET OF ADDONS
    echo -e "\n---"
    echo -e "Now link the default set of custom-addons to $OA_INSTANCEPATH/custom-addons-loaded\n"
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/chatterimprovements               $OA_INSTANCEPATH/custom-addons-loaded/  # Settion to Stop partners be automatically added as follower, Different colors for follower depending on setting
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_aeroo_default_reports      $OA_INSTANCEPATH/custom-addons-loaded/  # Basic aeroo reports for sales.order account.invoice and others
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_aeroo_reports_extensions   $OA_INSTANCEPATH/custom-addons-loaded/  # Add extra functions to aeroo reports like HEADER, or Show Images
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_base                       $OA_INSTANCEPATH/custom-addons-loaded/  # Export of openerp data with python Script, basic UI and CSS enhacements
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_customization_customer     $OA_INSTANCEPATH/custom-addons-loaded/  # All "small" customer customizations should be done in this addon - DO NOT UPDATE ;)
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_globalbcc                  $OA_INSTANCEPATH/custom-addons-loaded/  # Allow to send BCC Mails of OpenERP Messages automatically - Must be set per Modell
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_partner_fullhierarchy      $OA_INSTANCEPATH/custom-addons-loaded/  # Do not seperate between is Company or not - Easier handling of complex hirachies
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_partnernumber_unique       $OA_INSTANCEPATH/custom-addons-loaded/  # The Partner Number has to be unique sql-contrain - will add a new field and copy data of original field to new at install
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_project_advancedviews      $OA_INSTANCEPATH/custom-addons-loaded/  # Show related Tasks and Issues in Project Form, Show related Issues in Task Form
    ln -s  $OA_INSTANCEPATH/custom-addons/openat/openat_timetracking_setcharge     $OA_INSTANCEPATH/custom-addons-loaded/  # Allow to set type of charge to work log entries - NOT IDEAL - SHOULD Be FINISHED differently

    ln -s  $OA_INSTANCEPATH/custom-addons/camadeus/cam_hr_overtime                  $OA_INSTANCEPATH/custom-addons-loaded/  # Better Holiday and Overtime Handling including 30min Break
    ln -s  $OA_INSTANCEPATH/custom-addons/camadeus/cam_terminal                     $OA_INSTANCEPATH/custom-addons-loaded/  # Log Kommt Geht with a Terminal

    ln -s  $OA_INSTANCEPATH/custom-addons/aeroo/*                                   $OA_INSTANCEPATH/custom-addons-loaded/  # aeroo report engine

    ln -s  $OA_INSTANCEPATH/custom-addons/elico/mail_organizer                      $OA_INSTANCEPATH/custom-addons-loaded/  # Move Mails / Messages to other models and objects!
    ln -s  $OA_INSTANCEPATH/custom-addons/elico/web_polymorphic                     $OA_INSTANCEPATH/custom-addons-loaded/  # Needed because of mail_organizer

    ln -s  $OA_INSTANCEPATH/custom-addons/bhc/partner_city_autocomplete             $OA_INSTANCEPATH/custom-addons-loaded/  # Autocomplete city based on zip codes (csv file for austria has to be done by openat)
    ln -s  $OA_INSTANCEPATH/custom-addons/bhc/planning_management_shared_calendar   $OA_INSTANCEPATH/custom-addons-loaded/  # Shared/Super calender that can use any object of OpenERP
    #ln -s  $OA_INSTANCEPATH/custom-addons/bhc/planning_management_capacity_planning $OA_INSTANCEPATH/custom-addons-loaded/  # Project capacity planing http://www.bhc.be/en/application/capacity-planning

    ln -s  $OA_INSTANCEPATH/custom-addons/web-addons/web_ckeditor4                  $OA_INSTANCEPATH/custom-addons-loaded/  # CK-Editor 4 for text_html fields
    ln -s  $OA_INSTANCEPATH/custom-addons/web-addons/web_export_view                $OA_INSTANCEPATH/custom-addons-loaded/  # Export Tree Views to XLS
    ln -s  $OA_INSTANCEPATH/custom-addons/web-addons/web_popup_large                $OA_INSTANCEPATH/custom-addons-loaded/  # 95% width for popup overlay windows
    ln -s  $OA_INSTANCEPATH/custom-addons/web-addons/web_widget_float_formula       $OA_INSTANCEPATH/custom-addons-loaded/  # Allow formulas like =2*3-12 in float fields

    ln -s  $OA_INSTANCEPATH/custom-addons/server-env-tools/cron_run_manually          $OA_INSTANCEPATH/custom-addons-loaded/  # Run Cron Jobs Manually from their form view
    ln -s  $OA_INSTANCEPATH/custom-addons/server-env-tools/disable_openerp_online     $OA_INSTANCEPATH/custom-addons-loaded/  # Disable unsupported banner and remove links to oe-online
    ln -s  $OA_INSTANCEPATH/custom-addons/server-env-tools/email_template_template    $OA_INSTANCEPATH/custom-addons-loaded/  # Templates based on Templates for E-Mail Templates
    ln -s  $OA_INSTANCEPATH/custom-addons/server-env-tools/ir_config_parameter_viewer $OA_INSTANCEPATH/custom-addons-loaded/  # ir_config Parameter View
    ln -s  $OA_INSTANCEPATH/custom-addons/server-env-tools/mass_editing               $OA_INSTANCEPATH/custom-addons-loaded/  # Mass Editing of Objects

    ln -s  $OA_INSTANCEPATH/custom-addons/openerp-india/l10n_in_base                $OA_INSTANCEPATH/custom-addons-loaded/  # Custom filter as Tabs
    #ln -s  $OA_INSTANCEPATH/custom-addons/openerp-india/quotation_template          $OA_INSTANCEPATH/custom-addons-loaded/  # Custom filter as Tabs
    ln -s  $OA_INSTANCEPATH/custom-addons/openerp-india/web_group_expand            $OA_INSTANCEPATH/custom-addons-loaded/  # expand all grouped entries by level
    ln -s  $OA_INSTANCEPATH/custom-addons/openerp-india/web_filter_tabs             $OA_INSTANCEPATH/custom-addons-loaded/  # custom filter tabs
    ln -s  $OA_INSTANCEPATH/custom-addons/openerp-india/web_mail_img                $OA_INSTANCEPATH/custom-addons-loaded/  # Zoom images in mails

    ln -s  $OA_INSTANCEPATH/custom-addons/julius/document_extract_from_database     $OA_INSTANCEPATH/custom-addons-loaded/  # Save documents from DB to Filestore
    #ln -s  $OA_INSTANCEPATH/custom-addons/julius/email_confirmation                 $OA_INSTANCEPATH/custom-addons-loaded/  # Confirm Messages
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/google_map_and_journey             $OA_INSTANCEPATH/custom-addons-loaded/  # Show Route to Partner in Google Maps
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/object_merger                      $OA_INSTANCEPATH/custom-addons-loaded/  # Merge To Partners - and merges Subtypes like invoices and E-Mails
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/partner_history                    $OA_INSTANCEPATH/custom-addons-loaded/  # Collects a Message History for the Partner
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/project_description                $OA_INSTANCEPATH/custom-addons-loaded/  # Add a field for Project description
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/project_task_work_calendar_view    $OA_INSTANCEPATH/custom-addons-loaded/  # Add a calenderview to log times
    ln -s  $OA_INSTANCEPATH/custom-addons/julius/project_task_work_project          $OA_INSTANCEPATH/custom-addons-loaded/  # Log Work to tasks in time sheets and not Projects

    # Zimbra Connector is no longer a default addon! we will try to sync it with Opnerp > Talend Open Zimbra or Talend Open > Owncloud > Zimbra
    #ln -s  $OA_INSTANCEPATH/custom-addons/vnc/addons/*                              $OA_INSTANCEPATH/custom-addons-loaded/  # Zimbra connector addon part

    echo -e "\nDONE - Please link any additional addon(s) in custom-addons-loaded after installation to make them appear in openerp"
    echo -e "---\n"
fi

# SET correct owner and group
echo -e "Set the right user and group for $OA_INSTANCEPATH and its files"
chown $OA_DBUSER:$OA_DBUSER $OA_INSTANCEPATH -Rf


# Sucessfull end of script
echo -e "\n ##### SUCESSFULLY FINISHED SCRIPT: $SCRIPT in $SCRIPTPATH ##### \n"
