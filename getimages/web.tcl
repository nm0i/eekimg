#!/usr/bin/tclsh

set resultsPerPage 1

package require sqlite3
sqlite db urlmap.db

package require ncgi

::ncgi::parse
set pageNum [::ncgi::value p "0"]
set resultsPerPage [::ncgi::value pp 1]

::ncgi::header {text/html; charset=utf-8}

if { ($pageNum < 0) || ($pageNum > 1000) } {
	puts "Out of range"
	exit
}

if { ($resultsPerPage < 0) || ($resultsPerPage > 50) } {
	puts "Out of range"
	exit
}

set scriptName [file tail [info script]]

set imageCount [db eval {
	SELECT count(*)
	FROM descs
}]
set pageCount [expr {$imageCount / $resultsPerPage - 1}]

set pageSelector {}
if {$pageNum != 0 } {
	set pageSelector "<a href=\"$scriptName\">« </a>"
} {
	set pageSelector "« "
}
if {$pageNum > 1} {
	set pageSelector "${pageSelector}<a href=\"${scriptName}?p=[expr {$pageNum - 1}]\">← </a>"
} {
	set pageSelector "${pageSelector}← "
}
if {$pageNum >= 0 && $pageNum < $pageCount} {
	set pageSelector "${pageSelector}<a href=\"${scriptName}?p=[expr {$pageNum + 1}]\">→ </a>"
} {
	set pageSelector "${pageSelector}→ "
}
if {$pageNum != $pageCount} {
	set pageSelector "${pageSelector}<a href=\"${scriptName}?p=${pageCount}\">»</a>"
} {
	set pageSelector "${pageSelector}»"	
}

puts {<!DOCTYPE html>}
puts {<html xmlns="http://www.w3.org/1999/HTML" lang="en" xml:lang="en">}
puts {<!-- L29ah stinks -->}
puts {  <head>}
puts {    <meta charset="UTF-8"/>}
puts {    <link rel="alternate" title="EEK! Image board. RSS feed." href="rss.tcl" type="application/rss+xml"/>}
puts {	  <title>EEK! Image board!</title>}
puts {  </head>}
puts {  <body>}
puts {    <section>}
puts "    <a href=\"$scriptName\">"
puts {    <h1>Eek! Image Board!</h1>}
puts {    </a>}
puts "    Navigate: $pageSelector<br\>"

db eval {
	SELECT descs.hash, desc, descs.t, urlmap.url
	FROM descs
	INNER JOIN urlmap on urlmap.hash = descs.hash
	ORDER BY descs.t DESC
	LIMIT :resultsPerPage
	OFFSET :pageNum
} response {
	if 	{$response(desc) == "" } {
		set imgDesc "No fun part"
	} {
		set imgDesc $response(desc)
	}

	set t [clock format $response(t)  -format "%Y-%m-%d %H:%M"]
	
	puts {      <section>}
	puts "      <h1>$imgDesc</h1>"
	if {$pageNum != $pageCount} {
		puts "        <a href=\"${scriptName}?p=[expr {$pageNum + 1}]\">"
	} {
		puts "        <a href=\"${scriptName}\">"		
	}
	puts "          <img src=\"thumbs/${response(hash)}.jpg\" alt=\"$imgDesc\"/><br/>"
	puts "        </a>"

	puts "        <a href=\"$response(url)\">"
	puts "          the original"
	puts "        </a><br/>"
	puts "        added $t <br/>"
	puts {      </section>}
	puts {}
	
}
puts "    <br/>tap image to view the next<br/>"
puts "    Navigate: ${pageSelector}<br/>"
puts "    <a href=\"rss.tcl\">RSS</a><br/>"
puts {    </section>}
puts {  </body>}
puts {</html>}

puts {}
db close


