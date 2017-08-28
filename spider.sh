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
# @TODO:Add a urlTested to map all ressources already tested 1 time
# @TODO Refactor the recursivity, use wget to target only 1 page
#       then use an array to store the visited html ressources,
#       then loop over the remaining html available links if more
#       than 1 is given (also do not visit same url twice)
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
# 8 - Error in addUniqInArray
# 9 - Error in deleteInArray

# Default variables {{{1
flagGetOpts=0
args="${*}"
declare -a urlActualRessources
declare -a urlVisited
declare -a urlUnVisited
declare -a urlUnVisitedOutput

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

# function getDuperNumberInArray() {{{1
function getDupeNumberInArray() {
  name=$1[@]
  a=("${!name}")
  dupeTotal=0
  declare -a sortedArray
  for ((i=0; i<${#a[@]}; i++));
  do
    isInArray=0
    for u in "${sortedArray[@]}"
    do
      if [[ "${u}" == ${a[$i]} ]]; then
        isInArray=1
      fi
    done
    if [[ "$isInArray" -eq 0 ]]; then
      # Each value must be tested only once
      sortedArray=(${sortedArray[@]} ${a[$i]})
      # echo "sortedArray: ${sortedArray[@]}"
      # echo "searching:${i} - ${a[$i]}"
      dupeCount=0
      for ((j=0; j<${#a[@]}; j++));
      do
        if [[ "${a[$i]}" == "${a[$j]}" ]]; then
          # echo "There is a match on ${a[$i]}"
          dupeCount=$((dupeCount+1))
          # echo "dupecount: ${dupeCount}"
        fi
      done
      if [[ ${dupeCount} -ge 2 ]]; then
        # echo "there is more than 1 dupe"
        dupeTotal=$(( dupeTotal + dupeCount -1))
        # echo "dupeTotal: ${dupeTotal}"
      fi
    fi
  done
  echo "${dupeTotal}"
}

# function setDedupeInArray() {{{1
function setDedupeInArray() {
  echo "setDedupeInArray"
  name=$1[@]
  a=("${!name}")
  declare -a outputArray
  local i j
  for i in "${a[@]}"
  do
    dupe=0
    # echo "testing $i"
    for j in "${outputArray[@]}"
    do
      if [[ "$i" == "$j" ]]; then
        # echo "there is a match with $j"
        # already in the array
        dupe=1
      fi
    done
    if [[ "${dupe}" -eq 0 ]]; then
      # Not in the array
      # echo "$i not matched adding"
      outputArray=(${outputArray[@]} ${i})
      # echo "${outputArray[@]}"
    fi
  done
  echo "${outputArray[@]}"
}

# function valueIsInArray() {{{1
function valueIsInArray() {
  if [[ -n "$1" || -n "$2" ]]; then
    # Do the stuff
    name=$1[@]
    array=("${!name}")
    value="$2"
    match=0
    for item in "${array[@]}"
    do
      if [[ "$item" == "$value" ]]; then
        match=1
      fi
    done
  echo "${match}"
  else
    # One of the needed param is missing
    # inform the user and die
    echo "valueIsInArray: one of the var is empty"
    echo "\$1"
  fi
}

# function addUniqInArray() {{{1
# # first arg is array name
# # second arg is value
function addUniqInArray() {
  # local name value arrayItem valueFound
  local value arrayItem valueFound
  if [[ -n "$1" && -n "$2" ]]; then
    valueFound=0
    # Do the stuff
    name=$1[@]
    array=("${!name}")
    # declare -a array=("{!$1}")
    value="$2"
    for arrayItem in "${array[@]}"
    do
      if [[ "${arrayItem}" == "${value}" ]]; then
        valueFound=1
      fi
    done
    if [[ "${valueFound}" == 0 ]]; then
      # Add value to the array
      array=(${array[@]} ${value})
    fi
    echo "${array[@]}"
  else
    # One of the needed param is missing
    # inform the user and die
    echo "addUniqInArray: one of the var is empty"
    echo "\$1: $1"
    echo "\$2: $2"
    exit 8
  fi
}

# function deleteInArray() {{{1
# # first arg is array name
# # second arg is value
function deleteInArray() {
  local name value array
  if [[ -n "$1" && -n "$2" ]]; then
    name=$1[@]
    array=("${!name}")
    value="$2"
    for ((i=0; i<${#array[@]}; i++));
    do
      if [[ "${array[$i]}" == "$value" ]]; then
        unset array[$i]
      fi
    done
    echo "${array[@]}"
  else
    # One of the needed param is missing
    # inform the user and die
    echo "deleteInArray: one of the var is empty"
    echo "\$1: $1"
    echo "\$2: $2"
    exit 9
  fi
}

# Function isValueNotInArray() {{{1
function isValueNotInArray() {
  local name value array valueInArray
  if [[ -n "$1" && -n "$2" ]]; then
    name=$1[@]
    array=("${!name}")
    value="$2"
    valueInArray=0
    # echo "isValueNotInArray: testing $value"
    for ((i=0; i<${#array[@]}; i++));
    do
      # echo "isValueNotInArray: ${array[$i]} == $value"
      if [[ "${array[$i]}" == "$value" ]]; then
        valueInArray=1
      fi
    done
    echo "$valueInArray"
  else
    # One of the needed param is missing
    # inform the user and die
    echo "isValueNotInArray: one of the var is empty"
    echo "\$1: $1"
    echo "\$2: $2"
    exit 9
  fi
}

# function main() {{{1
function main() {
  # Add cmdUrl to urlUnVisited
  urlUnVisited=($(addUniqInArray urlUnVisited "${cmdUrl}"))
  # @FIXME Move that message to a debug / verbose mode
  echo "call web on: ${args}"
  # Now cmdLevel is not given to wget call but the number of loop below
  # We need to count the size of array to output to user
  urlActualRessources=($(bash ./web.sh -u "$cmdUrl" -l "1" -d "$cmdDomain"  ))
  # @FIXME: Refactor the duplication test + deduplication into a function
  # -> Begin of deduplication {{{2
  local dupeRessource
  dupeRessource=$(getDupeNumberInArray "urlActualRessources")
  # check ressources array for duplicate
  if [[ ${dupeRessource} -gt 0 ]]; then
    echo "dupe count: ${dupeRessource}"
    echo "deduplication"
    echo "${urlActualRessources[@]}"
    urlActualRessources=($(setDedupeInArray "urlActualRessources"))
    dupeRessource=$(getDupeNumberInArray "urlActualRessources")
    echo "After dedupeplication count: ${dupeRessource}"
  fi
  # <- End of test + deduplication 2}}}
  # @FIXME: Refactor the ressources probing into a function
  # -> Begin ressources probing
  # @FIXME Move that message to a debug / verbose mode
  echo "testing: ${urlUnVisited[0]}"
  echo "Number of ressources of the page: ${#urlActualRessources[@]}"
  echo "time:page state:URL"
  # This loop call prober (curl on each ressources of urlActualRessources)
  for i in "${urlActualRessources[@]}"
  do
    local timeBegin
    local timeEnd
    local timeTask
    local urlProber
    local urlHttp
    timeBegin="$(date +%s.%N)"
    # If it was tested for content-type just use the result
    # if [[ -n "$cmdFilter" ]]; then
    # else
    # fi
    if [[ -n "$cmdFilter" ]]; then
      # get the available content-type
      # @FIXME: export in a function
      content_type=( $(bash ./prober.sh -l simple) )
      urlProber="$(bash ./prober.sh -m 'content-type' -u "$i")"
      timeEnd="$(date +%s.%N)"
      if [[ "$(valueIsInArray content_type $urlProber)" == 0 ]]; then
        echo "Prober unknown content-type of $i"
        echo "content-type: ${urlProber}"
        exit 3
      fi
      urlHttp="${urlProber}"
    else
      urlProber="$(bash ./prober.sh -m 'http' -u "$i")"
      timeEnd="$(date +%s.%N)"
      # If not test it (one more curl call)
      urlHttp="$(bash ./prober.sh -m 'content-type' -u "$i")"
    fi
    # timeEnd="$(date +%s.%N)"
    timeTask=$(echo "$timeEnd - $timeBegin" | bc)
    timeTask="${timeTask:0:4}"
    # Does it need filtering ?
    if [[ -n "$cmdFilter" && "$cmdFilter" == "$urlProber" ]]; then
      getOutputConfigured "$timeTask" "$urlProber" "$i"
    elif [[ -z "$cmdFilter" && "$cmdFilter" == '' ]]; then
      getOutputConfigured "$timeTask" "$urlProber" "$i"
    fi
    # echo "urlHttp: ${urlHttp}"
    # Now if the ressource is a html type add it to unvisited array
    if [[ "${urlHttp}" == "html" ]]; then
      # if not already in the array we add it
      # We need to test that value is not in visited already
      # isValueNotInArray urlVisited ${i}
      if [[ "$(isValueNotInArray urlVisited ${i})" -eq '0' ]]; then
        urlUnVisited=($(addUniqInArray urlUnVisited "${i}"))
      fi

      # @FIXME: change that to a verbose mode
      #   echo "is not a url"
      #   echo "> ${urlHttp}"
    fi
  done
  # -> End ressources probing
  # Add it to the visited
  urlVisited=($(addUniqInArray urlVisited "${cmdUrl}"))
  # Delete from the unvisited
  urlUnVisited=($(deleteInArray urlUnVisited "${cmdUrl}"))
  # END Single pass
  # Do we need to continue iterating ?

  # basically just compare recursive parm if given with size of visited
  while [[ "${cmdLevel}" -gt "${#urlVisited[@]}" || "${cmdLevel}" == 0 ]] && [[ "${#urlUnVisited[@]}" -gt 0 ]];
  do
    # Diplay size of visited and unvisited to track progress
    echo "Visiting the page number ${#urlVisited[@]}"
    echo "Remaining page(s) to visit ${#urlUnVisited[@]}"
    echo "let's have a look at the next in unVisited"
    echo "testing: ${urlUnVisited[0]}"
    # 1 check if not already in visited (might be a default)
    # 2 send web to get the urlActualRessources array
    echo "webing on ${urlUnVisited[0]}"
    urlActualRessources=($(bash ./web.sh -u "${urlUnVisited[0]}" -l "1" -d "$cmdDomain"  ))
    echo "Number of ressources of the page: ${#urlActualRessources[@]}"
    # echo "size of urlActualRessources ${#urlActualRessources[@]}"
    # 3 loop on the ressources and probe the state
    # local ressource
    for i in "${urlActualRessources[@]}"
    do
      # echo "${ressource}"
      local timeBegin
      local timeEnd
      local timeTask
      local urlProber
      local urlHttp
      timeBegin="$(date +%s.%N)"
      if [[ -n "$cmdFilter" ]]; then
        # get the available content-type
        # @FIXME: export in a function
        content_type=( $(bash ./prober.sh -l simple) )
        urlProber="$(bash ./prober.sh -m 'content-type' -u "$i")"
        timeEnd="$(date +%s.%N)"
        if [[ "$(valueIsInArray content_type $urlProber)" == 0 ]]; then
          echo "Prober unknown content-type of $i"
          echo "content-type: ${urlProber}"
          exit 3
        fi
        urlHttp="${urlProber}"
      else
        urlProber="$(bash ./prober.sh -m 'http' -u "$i")"
        timeEnd="$(date +%s.%N)"
        # If not test it (one more curl call)
        urlHttp="$(bash ./prober.sh -m 'content-type' -u "$i")"
      fi
      # if [[ -n "$cmdFilter" ]]; then
      #   urlProber="$(bash ./prober.sh -m 'content-type' -u "$i")"
      # else
      #   urlProber="$(bash ./prober.sh -m 'http' -u "$i")"
      # fi
      timeTask=$(echo "$timeEnd - $timeBegin" | bc)
      timeTask="${timeTask:0:4}"
      # Does it need filtering ?
      if [[ -n "$cmdFilter" && "$cmdFilter" == "$urlProber" ]]; then
        getOutputConfigured "$timeTask" "$urlProber" "$i"
      elif [[ -z "$cmdFilter" && "$cmdFilter" == '' ]]; then
        getOutputConfigured "$timeTask" "$urlProber" "$i"
      fi
      # # If it was tested for content-type just use the result
      # if [[ -n "$cmdFilter" ]]; then
      #   urlHttp="${urlProber}"
      # else
      #   # If not test it (one more curl call)
      #   urlHttp="$(bash ./prober.sh -m 'content-type' -u "$i")"
      # fi
      # Now if the ressource is a html type add it to unvisited array
      if [[ "${urlHttp}" == "html" ]]; then
        # if not already in the array we add it
        # We need to test that value is not in visited already
        if [[ "$(isValueNotInArray urlVisited ${i})" -eq '0' ]]; then
          urlUnVisited=($(addUniqInArray urlUnVisited "${i}"))
        fi

        # @FIXME: change that to a verbose mode
        #   echo "is not a url"
        #   echo "> ${urlHttp}"
      fi
    done
    # 4 display to the user
    # 5 Add the html in unVisited if not already in there
    # Add it to the visited
    urlVisited=($(addUniqInArray urlVisited "${urlUnVisited[0]}"))
    # Delete from the unvisited
    urlUnVisited=($(deleteInArray urlUnVisited "${urlUnVisited[0]}"))
  done
}

main
# vim: set ft=sh ts=2 sw=2 tw=80 foldmethod=marker et :
