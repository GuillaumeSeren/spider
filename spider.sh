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
# @TODO: Explore all ressources but stay on the same domain.

# Error Codes {{{1
# 0 - Ok

# Default variables {{{1
flagGetOpts=0
defaultRLevel=1
args="$@"
declare -A urlPageList

# usage() {{{1
# Return the helping message for the use.
function usage()
{
cat << DOC

usage: "$0" options

This script explore a webapp and test ressources state.


OPTIONS:
    -h  Show this message.
    -u  url (needed)
    -l  recursivity level :
        n: default 1
        0: infinite
    -d  Define a target domain to focus.

Sample:
    Test a simple url
    "$0" -u guillaumeseren.com
    Find all linked ressources
    "$0" -u guillaumeseren.com -l 0 -d guillaumeseren.com

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:l:d:h" OPTION
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
    l)
        cmdLevel="$OPTARG"
        ;;
    d)
        cmdDomain="$OPTARG"
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

# main() {{{1
function main() {
    declare -a urlArray
    echo "testing: $cmdUrl"
    echo "call web on: $args"
    # urlArray=($(bash ./web.sh -u guillaumeseren.com -l1 ))
    urlArray=($(bash ./web.sh $args ))
    echo "call prober on array: ${#urlArray[@]}"
    # getLinkFromUrl "$cmdUrl"

    for i in "${urlArray[@]}"
    do
        urlStatus="$(bash ./prober.sh -u "$i")"
        echo "$urlStatus:$i"
    done
}

main
