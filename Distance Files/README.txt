README - Data Processing Files

Doug Brantner

All files are Python 2.7 unless otherwise noted.
Pandas version 0.17.1
Other modules as noted in ".q" files

Some of the shell scripts were written on Mac OSX which has strange behavior
with newlines in Sed, so literal newlines are used. These were not tested on
other Linux distributions, so strange behavior may occur.


############## HPC Files ############## 

High Performance Computing Files

These Python files were designed to run on the HPC with multiple cores
and large memory allotments. They should run on a regular personal computer,
however they may be significantly slower, and possible run into memory issues.
See the ".q" files for an example of how to call the files.

The ".q" files are job submit files for the NYU Mercer Cluster. 
These are Linux shell scripts which show how a file should be called.
The first few commented lines are instructions to the cluster
job management system to request memory, processors, etc.

See https://wikis.nyu.edu/display/NYUHPC/Writing+and+submitting+a+job

They may work on clusters with similar setups.

###### Distance to Nearest City ######

doc_dist.py
run_dists.q

Required data files:
	dr_data.csv
	big_wiki_cities.csv

Outputs:
	doc_cities_TEST.csv

###### Plot Payments ######

run_plot_pymt.q
plot_pymts.py

Required input files:
doc_cities_200k.csv
OP_DTL_GNRL_PGYR2013_P01152016.csv	(from CMS 2013 files)


###### Filter Medical Companies from ######

filter_comps.py
run_filter.q

Input files - any CSV file from the DIME Political Contribution data, eg.
	contribDB_2004.csv		(as "filename" below)

To call from command line there are several options:
To output list of doctors
	python -docs filename			

To output list of medical companies
	python -docs filename

To output both
	python -docs filename

To check if it's working without writing any files
	python -docs filename


############## Non-HPC Files ############## 
These files should run fine on a regular computer.


###### Medilexicon HTML Parsing ######

The Medilexicon HTML file is "malformed" HTML, and BeautifulSoup 
could not parse it. So we had to resort to a somewhat complicated
regular-expression based brute-force parsing, with some manual
cleaning afterward.

Use "medilex_fix3.sh" to parse the HTML file, then
"medilex_doZips.py" to compute Latitute/Longitude.

The ".sed" files are sed scripts that are called by the main shell script above.

medilex_fix1.sed
medilex_fix2.sed


###### Company Name Matching ######

Parse City Population table taken from
https://en.wikipedia.org/wiki/List_of_United_States_cities_by_population#cite_note-IndependentCity-15

Required Input File:
	table.csv

This is manually copied & paste from the Wikipedia page above, into NeoOffice Calc, and saved as a CSV file (to avoid manually parsing the HTML). 
This may also work in Excel, but behavior is not guaranteed.
 
(Excel may also work but may format CSV files differently, in which case the following may not work).

Then "parse_table.sh" is called from the command line, which calls the following support files:
	clean.awk
	clean.sed
	combine.awk

Outputs:
	table_combined.csv		(intermediate temp file)
	big_wiki_cities.csv		(final output)


###### Company Name Matching ######

fuzz_match.py

Takes two CSV files with lists of names, converts to lowercase, strips punctuation, and attempts to exactly match first word of each line.

This was an attempt at greedy matching of the first word in 
2 lists of strings (company names).
It sorts the lists first, and works 1 letter of the alphabet
at a time to minimize computation time.
