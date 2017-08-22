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
# @TODO Add visited array to be sure to not go infinite in case of recursion
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
# 2 - unknown content-type in prober
# 3 - Prober getUrlContentTypeSimple unknown content-type
# 4 - Prober Unknown option in mode
# 5 - Spider filter arg unknown
# 6 - Prober option unknown
# 7 - Error in getOutputConfigured args


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
        url         Add the url to the output
        ! You need at least 1 arg when configuring the output !
    -f  Filter on content-type, select one of:
        html | script | media | style

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
while getopts ":u:l:d:o:f:h" OPTION
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
      if [[ "$cmdOutput" =~ "url" ]]; then
        bOutputUrl=1
      fi
      # global validation
      if [[ "$bOutputTimer" != 1 && "$bOutputHttp" != 1 && "$bOutputUrl" != 1 ]]; then
        echo "Output error, the input did not match the pattern"
        usage
        exit 1
      fi
      ;;
    f)
      # @FIXME: validate available filter directly in the prober
      # @FIXME: Add multiple option instead of just one
      if [[ "$OPTARG" != 'html' && "$OPTARG" != 'script' && "$OPTARG" != 'media' && "$OPTARG" != 'style' ]]; then
        echo "Spider unknown filter: $OPTARG"
        usage
        exit 5
      fi
      cmdFilter="$OPTARG"
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

# function getOutputConfigured() {{{1
function getOutputConfigured() {
  local timeTask
  local urlProber
  local url
  # $1 is the timer
  # $2 is the probe status
  # $3 is the url
  # Let's break if either of the arg is not here
  if [[ -z "$1" || -z "$2" || -z "$3" ]]; then
    echo "Spider getOutputConfigured a arg is missing"
    echo "#1: $1"
    echo "#2: $2"
    echo "#3: $3"
    exit 7
  fi
  if [[ ! -z $bOutputTimer || -z $cmdOutput ]]; then
    timeTask="$1:"
  fi
  if [[ ! -z $bOutputHttp || -z $cmdOutput ]]; then
    urlProber="$2:"
  fi
  if [[ ! -z $bOutputUrl || -z $cmdOutput ]]; then
    url="$3"
  fi
  echo "$timeTask$urlProber$url"
}

# main() {{{1
function main() {
  declare -a urlArray
  echo "testing: $cmdUrl"
  echo "call web on: ${args}"
  urlArray=($(bash ./web.sh -u "$cmdUrl" -l "$cmdLevel" -d "$cmdDomain"  ))
  echo "call prober on array: ${#urlArray[@]}"

  echo "time:http state:URL"
  for i in "${urlArray[@]}"
  do
    timeBegin="$(date +%s.%N)"
    local urlProber
    if [[ ! -z "$cmdFilter" ]]; then
      urlProber="$(bash ./prober.sh -m 'content-type' -u "$i")"
    else
      urlProber="$(bash ./prober.sh -m 'http' -u "$i")"
    fi
    timeEnd="$(date +%s.%N)"
    timeTask=$(echo "$timeEnd - $timeBegin" | bc)
    timeTask="${timeTask:0:4}"
    # Does it need filtering ?
    if [[ -n "$cmdFilter" && "$cmdFilter" == "$urlProber" ]]; then
      getOutputConfigured "$timeTask" "$urlProber" "$i"
    elif [[ -z "$cmdFilter" && "$cmdFilter" == '' ]]; then
      getOutputConfigured "$timeTask" "$urlProber" "$i"
    fi
  done
}

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
