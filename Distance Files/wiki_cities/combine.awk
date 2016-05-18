BEGIN{
	# want to combine every 3 lines into single line
	tri = 0		# counter for every 3 lines
	comb = ""	# combined 3 lines to print
}
NR == 1 { print $0 }
NR > 1 {
	comb = comb $0			# combine lines
	tri += 1
	if (tri == 3) {		# reset
		print comb
		comb = ""
		tri = 0
	}
}
