#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   17/06/2015
# source:   https://github.com/GuillaumeSeren/spider
# file:     web.sh
# Licence:  GPLv3
# ---------------------------------------------


# usage() {{{1
# Return the helping message for the use.
function usage()
{
cat << DOC

usage: "$0" options

Explore a ressource URL and return linked URL.


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
while getopts "l:d:u:h" OPTION
do
    flagGetOpts=1
    case $OPTION in
    h)
        usage
        exit 1
        ;;
    u)
        cmdUrl="$OPTARG"
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

# getLinkFromUrl() {{{1
function getLinkFromUrl() {
    if [[ -n "$1" && "$1" != "" ]]; then
        tempFile="$(mktemp -d)"
        urlArray=($(wget --spider --force-html --page-requisites -P "$tempFile" -r "$rLevel" "$domainTarget" "$1" 2>&1 | grep '^--' | awk '{ print $3 }' | uniq))
        rm -r "$tempFile"

    else
        urlArray=()
    fi
}

# getRecursivityLevel() {{{1
function getRecursivityLevel(){
    if [[ -n "$1" && "$1" != "" ]]; then
        if [[ "$1" != 0 ]]; then
            local rLevel="-l $1"
        else
            local rLevel=""
        fi
    else
        local rLevel="-l 1"
    fi
    echo "$rLevel"
}

# getDomainTarget() {{{1
function getDomainTarget() {
    local domains=""
    if [[ -n "$1" && "$1" != "" ]]; then
            domains="--domains=$1"
    else
            domains=""
    fi
    echo "$domains"
}

# main() {{{1
function main() {
    # We need a recursive level
    rLevel=$(getRecursivityLevel "$cmdLevel")
    # Do we target a domain
    domainTarget=$(getDomainTarget "$cmdDomain")
    # Test URL
    declare -a urlArray
    getLinkFromUrl "$cmdUrl"

    for i in "${urlArray[@]}"
    do
        echo "$i"
    done
}

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
