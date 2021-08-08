#!/usr/bin/tclsh

package require ncgi

::ncgi::header {text/xml; charset=utf-8}

source rsslib.tcl

