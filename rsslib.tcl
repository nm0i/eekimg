#!/usr/bin/tclsh

set resultsPerPage 30

package require sqlite3
sqlite3 db urlmap.db

set scriptName [file tail [info script]]

puts "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<rss version=\"2.0\">
<channel>"

puts "<title>EEK! Image board!</title>"

db eval {
	SELECT descs.hash, desc, descs.t, urlmap.url
	FROM descs
	INNER JOIN urlmap on urlmap.hash = descs.hash
	ORDER BY descs.t DESC
	LIMIT :resultsPerPage
	OFFSET 0
} response {
	if 	{$response(desc) == "" } {
		set imgDesc "No fun part"
	} {
		set imgDesc $response(desc)
	}

	set t [clock format $response(t)  -format "%Y-%m-%d %H:%M"]

	puts "<item>"
    puts "<title>$imgDesc</title>"
    puts "<author>Unknown</author>"
    puts "<link>$response(url)</link>"
    puts "<description>"
	puts "<!\[CDATA\["
	puts "<a href=\"$response(url)\">"
	puts "<img src=\"thumbs/${response(hash)}.jpg\" alt=\"$imgDesc\"/><br/>"
	puts "click here to view the original"
	puts "</a><br/>"
	puts "added $t <br/>"
	puts " \]\]>"
    puts "</description>"
    puts "<pubDate>$t</pubDate>"
    puts "</item>"

	puts {}
	
}

puts "</channel>
</rss>"
db close


