#!/usr/bin/tclsh

set thumbScaling "640>x"
set imageViewer "feh"

package require term::ansi::send


term::ansi::send::import vt
vt::init

cd [file dirname [file normalize [info script]]]

package require sqlite3
auto_load sqlite3
sqlite3 db urlmap.db

# Table for image descriptions: hash, description, unix time (of
# description making).
catch {
    db eval {
        CREATE TABLE IF NOT EXISTS descs(
                                         hash TEXT,
                                         desc TEXT,
                                         t INTEGER,
                                         CONSTRAINT descs_pk PRIMARY KEY(hash))
    }
}

# Opening text file with list of hashes to process
if {[catch {
    set fileListing [open files.txt r]}
    ]} {
    vt::sda_fgred
    vt::wr "Could not open filex.txt, exiting."
    exit
}

# For each hash in that file...
while {[gets $fileListing line] != -1} {
    vt::sda_fgblue
    vt::wr "Categorizing $line.\n"

    if {! [file exists "images/${line}"]} {
        vt::sda_fgred
        vt::wr "No such file. Probably old files.txt, skipping.\n"
        continue
    }


    # Checking whether that hash already has a description
    set response [db eval {
        SELECT * FROM descs WHERE hash = :line
    }]

    if {$response != ""} {
        vt::sda_fgred
        vt::wr "hash:$line\nAlready exists in the db, skipping.\n"
        continue
    }

    # Displaying URL for that hash
    set response [db eval {
        SELECT url FROM urlmap WHERE hash = :line
    }]

    vt::sda_fggreen
    vt::wr "URL: $response\n"

    # If image viewer fails it most likely corrupted file or not an
    # image at all, so removing its file. Implies having image viewer
    # that can have non-zero exit...
    vt::sda_fgblue
    if {[catch {
        exec $imageViewer "images/${line}" &
    }]} {
        vt::sda_fgmagenta
        vt::wr "Image viewer failed to open images/${line}\n"
        vt::wr "Removing file images/${line}\n"
        file delete -- "images/${line}"
        continue
    }

    vt::wr "Description, (r)emove or (q)quit:\n"
    vt::sda_fgwhite

    gets stdin imgDesc
    if {$imgDesc == "r" || $imgDesc == ""} {
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
            INSERT OR REPLACE INTO descs (hash,desc,t) VALUES (:line,:imgDesc,:now);
        }
        vt::sda_fgyellow
        vt::wr "Making a thumbnail for ${line}..\n"
        exec -ignorestderr convert -scale $thumbScaling "images/${line}" "thumbs/${line}.jpg"
        vt::sda_fgmagenta
        vt::wr "Removing file images/${line}\n"
        file delete -- "images/${line}"
    }
}

close $fileListing
db close
vt::sda_reset
