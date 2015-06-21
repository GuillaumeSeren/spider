#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   17/06/2015
# source:   https://github.com/GuillaumeSeren/spider
# file:     prober.sh
# Licence:  GPLv3
# ---------------------------------------------

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
        # echo "Analyse url:$cmdUrl"
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

# getUrlStatus() {{{1
function getUrlStatus() {
    if [[ -n "$1" && "$1" != "" ]]; then
        httpStatus=$(curl --write-out %{http_code} --silent --output /dev/null "$1")
    else
        httpStatus=""
    fi
    echo "$httpStatus"
}

# main() {{{1
function main() {
    urlStatus="$(getUrlStatus "$cmdUrl")"
    echo "$urlStatus"
}

main
