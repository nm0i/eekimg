#!/bin/zsh

if [[ $1 == "src" ]]
then
	rsync -avze 'ssh'  ./eek.dcgi me0w:/opt/eekimg/
	rsync -avze 'ssh'  ./rsslib.tcl me0w:/opt/eekimg/
        rsync -avze 'ssh'  ./rss.cgi me0w:/opt/eekimg/
fi

if [[ $1 == "data" ]]
then
	rsync --delete -avze 'ssh'  ./urlmap.db me0w:/opt/eekimg/
	rsync --delete -avze 'ssh'  ./thumbs me0w:/opt/eekimg/
fi

