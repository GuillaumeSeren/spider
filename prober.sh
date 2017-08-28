#!/bin/bash
# -*- coding: UTF8 -*-
# ---------------------------------------------
# @author:  Guillaume Seren
# @since:   17/06/2015
# source:   https://github.com/GuillaumeSeren/spider
# file:     prober.sh
# Licence:  GPLv3
# ---------------------------------------------

# Variables {{{1
declare -A content_type=(
  [text/html]='html'
  [text/html\; charset=utf-8]='html'
  [text/html\; charset=\"UTF-8\"]='html'
  [text/html\; charset=UTF-8]='html'
  [text/plain]='text'
  [text/plain\;charset=UTF-8]='text'
  [text/xml\; charset=UTF-8]='xml'
  [application/xml]='xml'
  [image/png]='media'
  [image/gif]='media'
  [image/jpeg]='media'
  [text/javascript]='script'
  [application/javascript]='script'
  [text/css]='style'
  [application/rss+xml\; charset=utf-8]='feed'
  [application/atom+xml\; charset=utf-8]='feed'
  [application/rss+xml\; charset=\"UTF-8\"]='feed'
  [application/opensearchdescription+xml\; charset=utf-8]='search'
)

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

# getContentType() {{{1
# @FIXME: export usefull function in a lib file
# and use addUniqInArray()
function getContentType() {
  local key item match
  declare -a array
  for key in "${!content_type[@]}"
  do
    match='0'
    for item in "${array[@]}";
    do
      if [[ "${key}" == "${item}" ]]; then
        match='1'
      fi
    done
    # Si pas de match ou tableau vide
    if [[ "${match}" == "0" ]]; then
      array=(${array[@]} "${key}")
    fi
  done
  echo "${array[@]}"
}

# getSimpleContentType() {{{1
# @FIXME: export usefull function in a lib file
# and use addUniqInArray()
function getSimpleContentType() {
  local value item match
  declare -a array
  for value in "${content_type[@]}"
  do
    match='0'
    for item in "${array[@]}";
    do
      if [[ "${value}" == "${item}" ]]; then
        match='1'
      fi
    done
    # Si pas de match ou tableau vide
    if [[ "${match}" == "0" ]]; then
      array=(${array[@]} ${value})
    fi
  done
  echo "${array[@]}"
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
    # Check if the key exist
    if [ -n "${content_type[$1] + 1}" ]; then
      contentType="${content_type[$1]}"
    else
      echo "Prober unknown content-type of $1"
    fi
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

# GETOPTS {{{1
# Get the param of the script.
while getopts ":u:m:l:h" OPTION
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
      # nil or ''   default http content-type
      if [[ "$cmdMode" != '' && "$cmdMode" != 'http' && "$cmdMode" != 'content-type' ]]; then
        echo "Prober unknown mode : $cmdMode"
        exit 4
      fi
      ;;
    l)
      cmdList="$OPTARG"
      # List options
      if [[ "$cmdList" == 'simple' ]]; then
        #  || [[ "$cmdList" == 'full' ]];
        getSimpleContentType
      elif [[ "$cmdList" == "full" ]]; then
        getContentType
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

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
