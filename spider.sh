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
declare -A urlPageList

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

# getLinkFromUrl() {{{1
# @FIXME: We need a better solution because it run forever
function getLinkFromUrl() {
    if [[ -n "$1" && "$1" != "" ]]; then
        echo "check links in $1"
        urlArray=($(wget --spider --force-html -r "$1" 2>&1 | grep '^--' | awk '{ print $3 }' | uniq))
        # urlArray=($(ls -d */))
        echo "Not much links: ${#urlArray[@]}"
    else
        urlArray=()
    fi
}

# main() {{{1
function main() {
    # Test URL
    # urlStatus="$(getUrlStatus "$cmdUrl")"
    # echo "$urlStatus:$cmdUrl"
    declare -a urlArray
    getLinkFromUrl "$cmdUrl"
    for i in "${urlArray[@]}"
    do
        urlStatus="$(getUrlStatus "$i")"
        echo "$urlStatus:$i"
    done

    echo "${urlArray[2]}"
    # urlPageList["test"] = 'yes'
    
}

main
