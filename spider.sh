#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   17/06/2015
# source:   https://github.com/GuillaumeSeren/spider
# file:     spider.sh
# Licence:  GPLv3
# ---------------------------------------------

# TaskList {{{1
# @TODO: Return a list a ressource from a page.
# @TODO: Test a ressource and get HTTP code.
# @TODO: Explore all ressources but stay on the same domain.

# Error Codes {{{1
# 0 - Ok

# Default variables {{{1
flagGetOpts=0

# FUNCTION usage() {{{1
# Return the helping message for the use.
function usage()
{
cat << DOC

usage: "$0" options

This script explore a webapp and test ressources state.


OPTIONS:
    -h  Show this message.
    -u  url (needed)

Sample:
    Test a simple url
    "$0" -u guillaumeseren.com

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:h" OPTION
do
    flagGetOpts=1
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    u)
        cmdUrl="$OPTARG"
        echo "Analyse url:$cmdUrl"
        ;;
    ?)
        echo "commande $1 inconnue"
        usage
        exit
        ;;
    esac
done
# We check if getopts did not find no any param
if [ "$flagGetOpts" == 0 ]; then
    echo 'This script cannot be launched without options.'
    usage
    exit 1
fi

