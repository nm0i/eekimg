#!/usr/bin/tclsh

set thumbScaling "640x"
set imageViewer "feh"

package require term::ansi::send
term::ansi::send::import vt
vt::init

package require tclreadline
::tclreadline::readline initialize .categorize_history

cd [file dirname [file normalize [info script]]]

package require sqlite3
sqlite db urlmap.db

catch {
	db eval {
		CREATE TABLE IF NOT EXISTS descs(
										hash TEXT,
										desc TEXT,
										t INTEGER,
										CONSTRAINT descs_pk PRIMARY KEY(hash))
	}
}

if {[catch {
	set fileListing [open files.txt r]}
	]} {
	vt::sda_fgred
	vt::wr "Could not open filex.txt, exiting."
	exit
}

while {[gets $fileListing line] != -1} {
	vt::sda_fgblue
	vt::wr "Categorizing $line.\n"

	if {! [file exists "images/${line}"]} {
		vt::sda_fgred
		vt::wr "No such file. Old files.txt?.. Skipping\n"
		continue
	}

	set response [db eval {
		SELECT * FROM descs WHERE hash = :line
	}]

	if {$response != ""} {
		vt::sda_fgred
		vt::wr "hash:$line\nAlready exists in the db, skipping.\n"
		continue
	}
	
	vt::sda_fgblue
	exec -ignorestderr $imageViewer "images/${line}" &

	vt::wr "Description, (r)emove or (q)quit:\n"
	vt::sda_fgwhite
	set imgDesc [::tclreadline::readline read ""]
	if {$imgDesc == "r"} {
		vt::sda_fgmagenta
		vt::wr "Removing file images/${line}\n"
		file delete -- "images/${line}"
	} elseif {$imgDesc == "q"} {
		vt::sda_fgred
		vt::wr "Ok, quitting\n"
		break
	} else {
		set now [clock seconds]
		db eval {
			INSERT OR REPLACE INTO descs (hash,desc,t) VALUES (:line,:desc,:now);                         
		}
		vt::sda_fgyellow
		vt::wr "Making a thumbnail for ${line}..\n"
		exec -ignorestderr convert -scale $thumbScaling "images/${line}" "thumbs/${line}"
		vt::sda_fgmagenta
		vt::wr "Removing file images/${line}\n"
		file delete -- "images/${line}"
	}
}

close $fileListing
db close
vt::sda_reset

