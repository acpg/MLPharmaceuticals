# get rid of punctuation
s/[",%]\{1,\}//g

# get rid of all spaces
#s/ \{1,\}//g	
# moved to tr in calling shell script

# get rid of boxed references eg. [6]
s/\[.*\]//g


# this doesn't work
# get rid of "sq mi" and separate fields"
#2,$		s/;\([0-9\.]*\).*mi\([0-9\.]\).*km.*;/\1;\2/
#2,$		s/

