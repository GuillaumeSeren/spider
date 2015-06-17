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
