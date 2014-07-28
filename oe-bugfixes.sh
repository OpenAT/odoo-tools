#!/bin/bash
# Autor: Michael Karrer
# Date: 25.08.2013
# Version: 1.0
# Description: Here is a collection of usefull merges to the ocb Branches. For sure you have to do this manaully
#              and check if everything ins working!
# Usage: Copy this script to your instance addons folder and run it :)
#############

# [trunk/7.0]If you change the Unit of a Sales Order Line e.g. from Hour to Day the Description should not be lost
# https://bugs.launchpad.net/openobject-addons/+bug/1172239
bzr merge lp:~openerp-dev/openobject-addons/7.0-bug-1172239-cha ./addons


# Account_voucher : Onchange of amount removes all manually added lines
# https://bugs.launchpad.net/openobject-addons/6.0/+bug/783496
# NO FIX JET!!!


# HR Holiday remaining days unable to handle float
# https://bugs.launchpad.net/openobject-addons/+bug/1259971
# Fix available for trunk