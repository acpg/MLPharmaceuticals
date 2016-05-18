# call with LANG=C sed -f medilex_fix.sed medilex...html

# delete stuff before
1,499	d	

# delete everything after
510,$	d

# replace <br> tags with literal newline (only way it works on Mac :(
s/\<br\>/\
/g

# get company names
#s/.*\<h2.*style2\"\>\(.*\)\<\/h2\>/\1/p
#/\<h2/	p
