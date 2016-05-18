#!/bin/bash

# set env variable LANG=C to fix character encoding 
LANG=C

sed -f 'medilex_fix1.sed' medilexicon.html |	# strip unecessary HTML and split lines
sed -n -f 'medilex_fix2.sed' |					# extract name and zipcode
tr  '\n' ';' |									# replace newlines with ';' and records with ';;'
sed 's/;;/\
/g'	> medilexFINAL.csv							# replace ';;' with newline and save file
