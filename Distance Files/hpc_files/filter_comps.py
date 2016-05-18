import sys
import csv
import pandas as pd
import numpy as np

# Doug Brantner
# Constructs new filename from given name- WARNING- WILL OVERWRITE FILES!!!!

# Extract only medical Companies from Political Contribution files and save
#   Medical Companies: code starts with "H4"
#   Physicians: "H1[145]" regex

# call like this:
# python filter_comps.py filename

# TODO make output quoted?

# parse command line args
if sys.argv[1] == '-docs':
    mode = 'docs'
elif sys.argv[1] == '-comps':
    mode = 'comps'
elif sys.argv[1] == '-all':
    mode = 'all'
elif sys.argv[1] == '-test':     # dry run
    mode = 'test'
else:
    print "Error: required first arg is -docs or -comps"
    sys.exit(1)

fname = sys.argv[2]

print mode
print fname

# load file
# converter functions
corp_dict = {'corp': 1}
def conv_corp(c):
    #return c == 'corp'
    return corp_dict.get(c, 0) 

def conv_party(p):
    if p == '100':   # democrat
        return 1 
    elif p == '200': # republican
        return -1
    elif p == '328': # independent
        return 0
    else:
        return -2 # Nan, etc.

data = pd.read_csv(fname, sep=",", quotechar='"',
                   usecols=[ 'amount',
                                'bonica_cid',
                                'contributor_name',
                                'contributor_type',
                                'contributor_category',
                                'contributor_category_order',
                                'is_corp',
                                'organization_name',
                                'parent_organization_name',
                                'recipient_party',
                                'latitude',
                                'longitude' ],
                   dtype={   'amount': np.float32,
                                'bonica_cid': int,
                                'contributor_name': str,
                                'contributor_type': str, 
                                'is_corp': np.uint8,
                                'contributor_category': str,
                                'contributor_category_order': str,
                                'organization_name': str,
                                'parent_organization_name': str,
                                'recipient_party': int,
                                'latitude': np.float32,
                                'longitude': np.float32   },
                   converters={'is_corp': conv_corp,
                               'recipient_party': conv_party }  )


# get filename w/o extension
namesplit = fname.split(".")

if mode == 'comps' or mode == 'all':
    # filter H4 companies only
    med_comps = data[data.contributor_category.str.startswith("H4", na=False)]
    
    # create new filename and save 
    newname = namesplit[0] + "_comps.csv"
    med_comps.to_csv(newname, quoting=csv.QUOTE_NONNUMERIC)

    if mode == 'all':
        del med_comps   # clean up if 'all' is called

if mode == 'docs' or mode == 'all':
    # filter only physicians:
    pat = r'^H1[145]'
    docs = data[ data.contributor_category.str.match(pat, na=False, as_indexer=True) ]    

    newname = namesplit[0] + "_docs.csv"
    docs.to_csv(newname, quoting=csv.QUOTE_NONNUMERIC)

if mode == 'test':
    print data.shape

