#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   17/06/2015
# source:   https://github.com/GuillaumeSeren/spider
# file:     prober.sh
# Licence:  GPLv3
# ---------------------------------------------

# usage() {{{1
# Return the helping message for the use.
function usage()
{
cat << DOC

usage: "$0" options

Test a URL and return HTTP state.


OPTIONS:
    -h  Show this message.
    -m  Select the mode:
        '' | http:    return http code (default)
        content-type: return simplified content-type
    -u  url (needed)

Sample:
    Test a simple url
    "$0" -u guillaumeseren.com

DOC
}

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:m:h" OPTION
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
    m)
      cmdMode="$OPTARG"
      # validate allowed mode
      # nil or ''   default http
      # http
      # content-type
      if [[ "$cmdMode" != '' && "$cmdMode" != 'http' && "$cmdMode" != 'content-type' ]]; then
        echo "Prober unknown mode : $cmdMode"
        exit 4
      fi
      ;;
    ?)
      echo "commande $1 inconnue"
      usage
      exit 6
      ;;
  esac
done
# We check if getopts did not find no any param
if [ "$flagGetOpts" == 0 ]; then
  echo 'This script cannot be launched without options.'
  usage
  exit 1
fi

# getUrlHttpStatus() {{{1
function getUrlHttpStatus() {
  local httpStatus
  if [[ -n "$1" ]]; then
    httpStatus=$(curl --write-out %{http_code} --silent --output /dev/null "$1")
  else
    httpStatus=""
  fi
  echo "$httpStatus"
}

# getUrlContentType() {{{1
function getUrlContentType() {
  local httpContentType
  if [[ -n "$1" ]]; then
    httpContentType=$(curl --write-out %{content_type} --silent --output /dev/null "$1")
  else
    httpContentType=""
  fi
  echo "$httpContentType"
}

# getUrlContentTypeSimple() {{{1
function getUrlContentTypeSimple() {
  local contentType
  if [[ -n "$1" ]]; then
    case "$1" in
      'text/html')
        contentType='html'
        ;;
      'image/png' | 'image/gif')
        contentType='media'
        ;;
      'text/javascript')
        contentType='script'
        ;;
      'text/css')
        contentType='style'
        ;;
      *)
        echo "Prober unknown content-type of $1"
        exit 3
    esac
  else
    contentType=""
  fi
  echo "$contentType"
}

# main() {{{1
function main() {
  local result
  # check mode
  case "$cmdMode" in
    '' | 'http')
      result="$(getUrlHttpStatus "$cmdUrl")"
      ;;
    'content-type')
      result="$(getUrlContentType "$cmdUrl")"
      result="$(getUrlContentTypeSimple "$result")"
      ;;
  esac
  echo "$result"
}

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
