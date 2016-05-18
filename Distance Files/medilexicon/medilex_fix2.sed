# call with LANG=C sed -f medilex_fix.sed medilex...html

# delete telephone and fax numbers, etc.
/Tel/		d
/Fax/		d
/website/	d
/email/		d

# delete street addresses (lines that start w/ numbers and have text after)
/^[0-9]\{1,\} *.*[A-Za-z]\{1,\}/		d

# delete PO boxes (both PO and P.O.)
#/P\.*O\.* Box/	d
#/P\.*O\.* BOX/	d
/Box/	d
/BOX/	d

# get company names
/\<h2/		s/.*\<h2.*style2\"\>\(.*\)\<\/h2\>/\1/p

# get zip codes	('&' should replace w/ found pattern)
# print extra newline after
/[0-9]\{5\}/		s/^.*\([0-9]\{5\}\).*$/\1\
/p
