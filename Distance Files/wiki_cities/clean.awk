# Doug Brantner
# copy first 6 columns, then split the land area/pop density columns, and split GPS Lat/Lon

BEGIN{
	FS=";"	# semicolon delimited
	c1 = 1	# print columns c1 thru c2 as is
	c2 = 6
}

NR == 1 {	# clean headers
	out = printcols(c1,c2)
	out = out "2014landAreaMi2;2014landAreaKm2;2010popDensMi2;2010popDensKm2;Lat;Lon"
	print out
}

NR > 1 {
	out = printcols(c1,c2)

	sub(/sqmi/, ";", $7)	# change sqmi to a semicolon to split fields
	sub(/km2/,   "", $7)	# delete km2
	out = out $7 FS

	sub(/persqmi/, ";", $8)		# split fields
	sub(/km.*2/,    "", $8)		# delete remaining text
	out = out $8 FS				# concat with a delimeter at end

	# parsing Lat/Lon - Assuming all are North or West (since it's only continental US)
	n = index($9, "N")
	lat = substr($9, 1, n-3)		# -3 to get rid of "N" and degree symbol (apparently it's 2 chars?)
	l2 = length($9) - n - 3			# 2nd string length for substr
	lon = substr($9, n+1, l2)	
	out = out lat ";-" lon			# add "-" because West Longitude is negative

	print out
}

function printcols(s, t) {
	# return all columns from s to t, with FS separator in between *and* after
	out = $s
	for (i = s + 1; i <= t; i++) {
		out = out FS $i
	}
	return out FS
}
