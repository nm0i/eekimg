#!/usr/bin/tclsh

package require term::ansi::send
term::ansi::send::import vt
vt::init

package require sha256

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

while {[gets $fileID line] != -1} {
	set key [::sha2::sha256 $line]
    catch {
		vt::sda_fgblue
		exec -ignorestderr snarf -m $line "images/${key}"

		set now [clock seconds]
		
		vt::sda_fgyellow
		vt::wr "$now $key | $line\n"    
		db eval {    
			INSERT OR REPLACE INTO urlmap (hash,url,t) VALUES (:key,:line,:now);                         
		}            		
	}
}
vt::sda_reset

