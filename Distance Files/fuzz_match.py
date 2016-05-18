import string
from fuzzywuzzy import fuzz
from string import ascii_lowercase

# Doug Brantner
# 8 May 2016

# Greedy first-word fuzzy string matcher
# NOTE - only checks 1st words- so still need to check accuracy


# Things To Do...
# TODO generate hashed ID so it's unique AND new names can be added arbitrarily
    # NOTE need to merge many files eventually, to unique company ID
# TODO load full csv, match name column, then output full csv w/ mapped ID
# TODO maybe add Levenshtein distance to judge matches
    # TODO check fuzzywuzzy docs for ratio, partial_ratio, etc
# TODO test matches, 2nd word, 3rd word, etc.
# TODO remove duplicate names from list (or better, map to same name) - maybe this is external responsibility...
# TODO time block-matching vs full list matching


def get_first_words(L, d=" "):
    # list comp to extract 1st word (delimited by space) in list
    # L = list of strings
    # d = delimiter

    return [l.split(d)[0] for l in L]

def match_first_word(Li1, Li2):
    # assumptions (eg. responsibility of caller):
    # L1 and L2 are LOWERCASE
    # L1 and L2 have punctuation stripped (only 0-9a-z and spaces allowed)
    # L1 and L2 are sorted AFTER the above are done, in ascending alphabetic order
    # L1 and L2 are a subset of the main lists, such that the first letter is uniformly the same
        # eg. L1 and L2 contain ONLY strings starting with 'a'

    if len(Li1) > len(Li2):   # L1 should be the shorter of the two
        L1 = get_first_words(Li2)
        L2 = get_first_words(Li1)
        flip = True         # need to reverse results at end (?)
    else:
        L1 = get_first_words(Li1)
        L2 = get_first_words(Li2)
        flip = False

    M = []  # list of tuples of matches

    i = 0
    lasti = -1
    while i < len(L1):

        match = False
        j = lasti + 1
        while (not match) and j < len(L2):
            if L1[i] == L2[j]:
                match = True
                M.append( (i, j) )
                lasti = i
            else:
                j += 1

            #print L1[i] + "\t" + L2[j] + "\t" + str(match)

        i += 1

    if flip:    # flip (i,j) in M if necessary
        M = [(j,i) for (i,j) in M]

    return M


def fix_list(L):
    # strip punctuation, set to lowercase, and sort L
    exclude = set(string.punctuation)
    table = string.maketrans("","")
    L = [s.translate(table, string.punctuation).lower() for s in L]
    L.sort()
    return L


def print_diff(L1, L2, M, delim="\t", print_mismatches=True):
    # L1, L2 lists of words
    # M = list of match tuples
    # delim = delimeter for printing

    # TODO make cleaner columns (maybe more tabs?)

    print "List1" + delim + "List2" + delim + "FuzzRatio"

    i0 = -1 
    j0 = -1 
    for (i1,j1) in M:

        # print all mismatches separately before first match
        #(i0,j0) = M[0]
        if print_mismatches:
            for i in xrange(i0+1, i1):
                print L1[i] + delim*2       # print 2 empty fields

            for j in xrange(j0+1, j1):
                print delim + L2[j] + delim # same empty fields as above

        # print matches and stagger mismatches in between:
        print L1[i1] + delim + L2[j1] + delim + str(fuzz.ratio(L1[i1], L2[j1]))        # print match together 
        
        i0 = i1
        j0 = j1

    # print remainder of lists (trailing non-matches)
    if print_mismatches:
        for i in xrange(i0+1, len(L1)):
            print L1[i] + delim*2

        for j in xrange(j0+1, len(L2)):
            print delim + L2[j] + delim


def test():
    # from cms2013 sort2 list
    testL1 = ['A-dec, Inc.','Aaren Scientific Inc.','ABB Con-Cise Optical Group LLC','Abbott Laboratories','AbbVie, Inc.','ABEON MEDICAL CORPORATION','ABIOMED','ABL Medical, LLC','Abraxis BioScience, LLC','Accel SPINE, LLC','Accellent Inc.','Access Closure, Inc','Acclarent, Inc','ACCURAY INCORPORATED','Accuray Incorporated','ACE Surgical Supply Co., Inc.','ACell, Inc.','Acorda Therapeutics, Inc','Actavis Pharma Inc','Actelion Clinical Research, Inc.','Actelion Pharmaceuticals US, Inc.','Actelion Pharmaceuticals, Ltd','Active Medical, LLC','ACUMED LLC','Acute Innovations, LLC','Advanced Bionics, LLC','Advanced Circulatory Systems Inc.','Advanced Critical Devices, Inc.','Advanced Medical Partners Inc','Advanced Orthopaedic Solutions, Inc.','Advanced Respiratory, Inc','Aegerion Pharmaceuticals, Inc.','Aero-Med LTD','Aerocrine, Inc','Aesculap AG','Aesculap Akademie GmbH','Aesculap Biologics, LLC','Aesculap Implant Systems, LLC','Aesculap, Inc.','Afaxys, Inc.','Affordable Pharmaceuticals, LLC','Agfa HealthCare Corporation','Akorn Inc.','AKRIMAX PHARMACEUTICALS, LLC','Alcon Laboratories Inc','Alcon Pharmaceuticals Ltd','Alcon Puerto Rico Inc','Alcon Research Ltd','ALERE HOME MONITORING, INC.','Alere Informatics, Inc.','Alere North America, LLC','Alere San Diego, Inc.','Alexion Pharmaceuticals, Inc.','Alexza Pharmaceuticals, Inc.','Algeta US LLC','ALK-Abello, Inc','Alk-Abello, Inc','Alkermes, Inc.','Allerderm  Laboratories','Allergan Inc.','Alliance Partners LLC','Alliqua  BioMedical, Inc.','AlloSource','Alpha Orthopedic Systems','Alphatec Spine, Inc','Alpine Implant Alliance, LLC','Alpine Surgical Technologies, LLC','Altatec GmbH','AMAG Pharmaceuticals, Inc.','Amarin Pharma Inc.','AMD Lasers LLC','Amedica Corporation','Amendia, Inc.','American Medical Hospital Supply Company, Inc.','American Medical Systems Inc.','AMERICAN MEDICAL TECHNOLOGY INC','American Orthodontics Corporation','AmerisourceBergen Drug Corporation','Amgen Inc.','Amniox Medical','Analogic Corporation','AngioDynamics, Inc.','AngioScore, Inc.','Anika Therapeutics, Inc.','Animas Corporation','APO-PHARMA INC.','APO-PHARMA USA, INC.','APOLLO ENDOSURGERY INC','Apollo Surgical Group, LLC','Applied Medical Australia, Pty, Ltd.','Applied Medical Europe BV','Applied Medical Resources Corporation','APPLIED MEDICAL TECHNOLOGY INC','Applied Medical Technology Inc','Aptalis Pharma US, Inc','Aptis Medical, LLC','Aqua Pharmaceuticals','Arbor Pharmaceuticals, Inc.','ARGON MEDICAL DEVICES, INC.','ARIAD Pharmaceuticals, Inc.','Aribex Inc.','Ariosa Diagnostics, Inc.','Arizona Cryosurgical Partnership LP','Arjohuntleigh, Inc.','ARKRAY USA, Inc.','Arrow International, Inc.','Arrow Interventional, Inc.','Art Optical Contact Lens Inc.','Arteriocyte Medical Systems, Inc.','Arthrex, Inc.','ArthroCare Corporation','Arthrosurface Incorporated','ASAHI INTECC CO., LTD.','ASAHI INTECC USA, INC.','AsahiKasei Medical Co.,Ltd.','ASCEND Therapeutics US, LLC','Ascension Orthopedics, Inc.','ASD Specialty Healthcare, Inc.','Aseptico, Inc.','Astellas Pharma Europe BV','Astellas Pharma Global Development','Astellas Pharma Inc','Astellas Pharma US Inc','Astellas Scientific and Medical Affairs','AstraZeneca AB','AstraZeneca Pharmaceuticals LP','AstraZeneca UK Limited','Asuragen, Inc.','Atlantic Coast Cryotherapy LP','Atlas Spine, Inc.','Atos Medical Inc','AtriCure, Inc.','Atrium Medical Corporation','Auxilium Pharmaceuticals, Inc.','Avanir Pharmaceuticals, Inc.','AVID RADIOPHARMACEUTICALS, INC.','Avinger Inc.','Avion Pharmaceuticals','AXOGEN' ]

  # from wikipedia list
  # NOTE - sorted w/ case sensitive- so Abbott and AbbVie are flipped in L1 above
    testL2 = ['Abbott Laboratories','AbbVie','Acadia Pharmaceuticals','Acorda Therapeutics','Actavis','Actelion','Advanced Chemical Industries','Advaxis','Ajanta Pharma','Alcon','Alexion Pharmaceuticals','Alkaloid','Alkermes','Allergan','Alliance Boots','Almirall','Alphapharm','Altana Pharma AG','Amgen','Amico Laboratories','Apotex Inc.','Astellas Pharma','AstraZeneca','Aurobindo Pharma','Avax Technologies','Avella Specialty Pharmacy','Axcan Pharma']

    #global testL1
    #global testL2
    
    testL1 = fix_list(testL1)
    testL2 = fix_list(testL2)
    #print testL1
    #print testL2

    # TODO need to lowercase, and re-sort 
    ml = match_first_word(testL1, testL2)
    print ml
    print

    print_diff(testL1, testL2, ml, False)
    #for (i,j) in ml:
    #    print testL1[i] + "\t" + testL2[j]

#test()

def load_file(name, break_char="-1"):
    # name = path to file
    # break_char = character to stop at; default -1 should never match -> read whole file

    if break_char != "-1":
        break_char = break_char.lower()

    L = []
    with open(name, "r") as f:

        # TODO: maybe do an external if break_char == -1, to avoid checking each time in loop if it's not wanted
        for line in f:
            if line[0].lower() == break_char:
                break
            L.append(line.strip())
            
    return L





def find_letter_breaks(L):
    # find letter breaks and return index 
    # returns dict { character : index of first occurrence in L }

    i = 0

    # find first alphabetical character
    alpha = False
    while (not alpha) and i < len(L):
        x = ord(L[i][0]) 
        if x >= 97 and x <= 122:
            alpha = True
        else:
            i += 1
    
    # TODO break early if no alpha chars are found?

    c = chr(x)   
    cdict = {}
    first = i   # store starting index of letter c

    i += 1 # start at next line and check first chars
    while i < len(L):       
        if L[i][0] != c:
            last = i - 1
            cdict[c] = (first, last)
            c = L[i][0] 
            first = i
        i += 1

    cdict[c] = (first, len(L) - 1)  # have to do last one manually

    return cdict

def find_letter_breaks2(L):
    # same as above, but return a dict of tuples with (start, end) for each character

    i = 0
    alpha = False
    while (not alpha) and i < len(L):
        pass


def print_letter_dict(D):
    # print indexes stored in dictionary w/ alpha character keys

    # alternate form for looping over alphabet:
    # http://stackoverflow.com/questions/17182656/how-do-i-iterate-through-the-alphabet-in-python-please

    #for i in xrange(ord('a'), ord('z') + 1):
    for c in ascii_lowercase:
        #c = chr(i)
        print c + ":\t" + str(D.get(c, -1)) 

def print_list(L):
    for l in L:
        print l
        

def test_files():
    f1 = 'cms2013/cms2013_namesonly.csv'
    f2 = 'wikiPharma/wiki_list_namesonly.csv'

    c = 'e'
    L1 = load_file(f1) #, break_char=c)
    L2 = load_file(f2) #, break_char=c)

    L1 = fix_list(L1)
    L2 = fix_list(L2)


    L1dict = find_letter_breaks(L1)
    L2dict = find_letter_breaks(L2)
    #print_letter_dict(L2dict)      # for testing index accuracy
    #print_list(L2)
    
    
    # match one letter group at a time
    matchlist = []
    firstloop = True        # need to cover anything before 'a'
    for c in ascii_lowercase:
        (L1start, L1end) = L1dict.get(c, (-1, -1))
        (L2start, L2end) = L2dict.get(c, (-1, -1))


        if (L1start != -1) and (L2start != -1): # skip solving if one list doesn't contain any matches
            if firstloop:       # lump any numbers, etc. in with first letter (not ideal, but...)
                L1start = 0 
                L2start = 0
                firstloop = False
            
            ml = match_first_word(L1[L1start:L1end + 1], L2[L2start:L2end + 1])
            if len(ml) > 0:
                ml = [ (i + L1start, j + L2start) for (i,j) in ml ] # correct for index offsets
                matchlist.extend(ml)

    print_diff(L1, L2, matchlist, delim=";", print_mismatches=True)


test_files()
