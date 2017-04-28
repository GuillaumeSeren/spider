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
# @TODO Add actual page that host the link
# @TODO Add support for login (cookie / session)
# @TODO Add a way to define a route to simulate a user
# @TODO Add stress test option (ab) to simulate a group.
# @TODO Add parallel process for web & prober (perf)
# @TODO Discover recursively all ressources, too slow actually (v8 perf)
# @TODO Generate a dependency graph to represent the webapp (niceToHave)
# @TODO Add a DB to store the graph, and request it (niceToHave)
# @TODO Add a sorting option (by speed, by http code niceToHave)

# Error Codes {{{1
# 0 - Ok
# 1 - Output error, the input did not match the pattern

# Default variables {{{1
flagGetOpts=0
args="${*}"

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
    -o  Define the output : (comma separated, default add everything)
        timer       Add the timer in the output
        http_code   Add the http_code return in the output

Sample:
    Test a simple url
    "$0" -u guillaumeseren.com
    Find all linked ressources
    "$0" -u guillaumeseren.com -l 0 -d guillaumeseren.com
    "$0" -u guillaumeseren.com -o http_code

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:l:d:o:h" OPTION
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
    o)
        cmdOutput="$OPTARG"
        # We need to check if there is a , in the string input explode-like
        # if yes we split into an array and test each entry for each
        # if no there should be only one entry.
        if [[ "$cmdOutput" =~ "timer" ]]; then
          bOutputTimer=1
        fi
        if [[ "$cmdOutput" =~ "http_code" ]]; then
          bOutputHttp=1
        fi
        if [[ $bOutputTimer != 1 && $bOutputHttp != 1 ]]; then
          echo "Output error, the input did not match the pattern"
          usage
          exit 1
        fi
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
    echo "call web on: ${args}"
    # urlArray=($(bash ./web.sh ${args} ))
    urlArray=($(bash ./web.sh -u "$cmdUrl" -l "$cmdLevel" -d "$cmdDomain"  ))
    echo "call prober on array: ${#urlArray[@]}"

    echo "time:http state:URL"
    for i in "${urlArray[@]}"
    do
        timeBegin="$(date +%s.%N)"
        # urlStatus="$(bash ./prober.sh -u "$i")"
        if [[ ! -z $bOutputHttp || -z $cmdOutput ]]; then
          urlStatus="$(bash ./prober.sh -u "$i")"
          urlStatus="$urlStatus:"
        fi
        timeEnd="$(date +%s.%N)"
        if [[ ! -z $bOutputTimer || -z $cmdOutput ]]; then
          timeTask=$(echo "$timeEnd - $timeBegin" | bc)
          timeTask="${timeTask:0:4}:"
        fi
        # timeTask=$(echo "$timeEnd - $timeBegin" | bc)
        # echo "${timeTask:0:4}$urlStatus$i"
        # echo "${timeTask:0:4}:$urlStatus:$i"
        echo "$timeTask$urlStatus$i"
    done
}

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
