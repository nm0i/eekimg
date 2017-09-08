#!/usr/bin/tclsh

package require term::ansi::send
term::ansi::send::import vt
vt::init

package require sha256
package require Tclx

package require sqlite3
sqlite db urlmap.db

catch {
	db eval {
		CREATE TABLE IF NOT EXISTS urlmap(
										hash TEXT,
										url TEXT,
										t INTEGER,
										CONSTRAINT urlmap_pk PRIMARY KEY(hash))
	}
}

set fileID [open urls.txt r]
set i 1

while {[gets $fileID line] != -1} {
	set key [::sha2::sha256 $line]
	catch {

		set response [db eval {
			SELECT * FROM urlmap WHERE hash = :key
		}]

		if {$response != ""} {
			vt::sda_fgred
			vt::wr "URL:$line\nAlready exists in the db, skipping.\n"
			continue
		}

		set now [clock seconds]
		
		vt::sda_fgyellow
		vt::wr "$i "
		vt::sda_fgwhite
		vt::wr "$now $key | $line\n"
		db eval {
			INSERT OR REPLACE INTO urlmap (hash,url,t) VALUES (:key,:line,:now);                         
		}
		
		vt::sda_fgblue
		exec -ignorestderr wget --timeout=10 -U "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36" --no-check-certificate $line -O "images/${key}"
		incr i
		sleep 1
	}
}

db close
vt::sda_reset

