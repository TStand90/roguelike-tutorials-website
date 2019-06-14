#!/bin/bash

for f in $(ls content/tutorials/tcod/*.html.bak) 
do 
	name=${f%.html.bak}.md
	head -n 5 $f > $name
	tail -n +6 $f |
        perl -wpe 's/\h?(.*)$/+$1/ if /^\h*<span style="color: green"/ ..  /<\/span>/; s/\h?(.*)$/-$1/ if /^\h*<span style="color: red/ ..  /<\/span>/' |
		pandoc -f html -t gfm+backtick_code_blocks |
		grep -Ev '<div>|</div>' >> $name
done

