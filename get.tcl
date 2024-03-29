#!/usr/bin/tclsh

package require term::ansi::send
term::ansi::send::import vt
vt::init

cd [file dirname [file normalize [info script]]]

package require sha256

package require sqlite3
auto_load sqlite3
sqlite3 db urlmap.db

catch {
    db eval {
        CREATE TABLE IF NOT EXISTS urlmap(
                                          hash TEXT,
                                          url TEXT,
                                          t INTEGER,
                                          CONSTRAINT urlmap_pk PRIMARY KEY(hash))
    }
}

set fileURLS [open urls.txt r]
set fileListing [open files.txt a]
set i 0

while {[gets $fileURLS line] != -1} {
    set key [::sha2::sha256 $line]
    catch {

        incr i

        set response [db eval {
            SELECT * FROM urlmap WHERE hash = :key
        }]

        if {$response != ""} {
            vt::sda_fgred
            vt::wr "URL:$line\nAlready exists in the db, skipping.\n"
            continue
        }

        set now [clock seconds]

        vt::sda_fgwhite
        vt::wr "$i "
        vt::sda_fgyellow
        vt::wr "$now "
        vt::sda_fggreen
        vt::wr "$key "
        vt::sda_fgyellow
        vt::wr "$line\n"
        db eval {
            INSERT OR REPLACE INTO urlmap (hash,url,t) VALUES (:key,:line,:now);
        }

        puts $fileListing $key

        vt::sda_fgblue
        exec -ignorestderr wget --timeout=10 --tries=1 -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36" --no-check-certificate $line -O "images/${key}"
        sleep 1
    }
}

db close
close $fileURLS
close $fileListing
vt::sda_reset
