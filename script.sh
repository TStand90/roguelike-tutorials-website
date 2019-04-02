#!/bin/bash

for f in $(ls content/tutorials/tcod/*.html.bak) 
do 
	name=${f%.html.bak}.md
	head -n 5 $f > $name
	tail -n +6 $f |
		perl -wpe 'print "+ " if /^\s*<span style="color: green"/ .. /<\/span>/; print "- " if /^\s*<span style="color: red/ .. /<\/span>/' |
		pandoc -f html -t markdown-smart |
		grep -Ev '<div>|</div>' >> $name
done

