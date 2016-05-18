#!/bin/bash

# Doug Brantner
# April 28, 2016

# original file lines are split (because of newlines in original text). So re-combine them.
awk -f combine.awk < table.csv > table_combined.csv

# clean out unnecessary characters
cat table_combined.csv	|	
tr  -d [:blank:]        | 
sed -f clean.sed        |
awk -f clean.awk        >	big_wiki_cities.csv
