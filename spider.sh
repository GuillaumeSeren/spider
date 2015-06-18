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

Sample:
    Test a simple url
    "$0" -u guillaumeseren.com
    Find all linked ressources
    "$0" -u guillaumeseren.com -l 0

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:l:h" OPTION
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

# getLinkFromUrl() {{{1
function getLinkFromUrl() {
    if [[ -n "$1" && "$1" != "" ]]; then
        echo "check links in $1"
        tempFile="$(mktemp -d)"
        echo "Use tempFile: $tempFile"
        urlArray=($(wget --spider --force-html -P "$tempFile" -r "$rLevel" "$1" 2>&1 | grep '^--' | awk '{ print $3 }' | uniq))
        echo "Not much links: ${#urlArray[@]}"
        rm -r "$tempFile"
        echo "cleaned tempFile"

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
        local rLevel="-l $defaultRLevel"
    fi
    echo "$rLevel"
}

# main() {{{1
function main() {
    # We need a recursive level
    rLevel=$(getRecursivityLevel "$cmdLevel")
    # Test URL
    # urlStatus="$(getUrlStatus "$cmdUrl")"
    # echo "$urlStatus:$cmdUrl"
    declare -a urlArray
    echo "testing: $cmdUrl"
    getLinkFromUrl "$cmdUrl"

    for i in "${urlArray[@]}"
    do
        urlStatus="$(getUrlStatus "$i")"
        echo "$urlStatus:$i"
    done
}

main
