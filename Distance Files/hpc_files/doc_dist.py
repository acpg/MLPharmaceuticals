import numpy as np
import pandas as pd
import multiprocessing
from sklearn.metrics.pairwise import pairwise_distances
# https://github.com/scikit-learn/scikit-learn/blob/51a765a/sklearn/metrics/pairwise.py#L1105

def haversine(point1, point2):
    """
     input: 2 points as numpy arrays [Lat, Lon]
     returns: distance in km

    # code modified from 'haversine' library
    # https://github.com/mapado/haversine/blob/master/haversine/__init__.py
        # modified to use numpy instead of 'math'
        # making it callable from sklearn...pairwise_distances
        # removed if/else for miles conversion to avoid branching slowdown
        # ---> multiply by 0.621371    to convert to miles
    """

    # convert all latitudes/longitudes from decimal degrees to radians
    point1 = np.radians(point1)
    point2 = np.radians(point2)

    s = np.square( np.sin( 0.5 * (point2 - point1) ) )
    d = s[0] + np.cos(point1[0]) * np.cos(point2[0]) * s[1]

    #h = 2 * AVG_EARTH_RADIUS * asin(sqrt(d))
    return 2. * 6371. * np.arcsin( np.sqrt(d) )


print "# CPUs: %d\n\n" % multiprocessing.cpu_count()

# Load Dr. File
docfile = 'cms_2013/dr_data.csv'
docid  = 'Physician_Profile_ID'
doclat = 'INTPTLAT'
doclon = 'INTPTLONG'
docs = pd.read_csv(docfile, sep=',', quotechar='"', 
                    usecols=[docid, doclat, doclon], 
                    #nrows=2000,    # short list for testing
                    dtype={ docid:  np.uint32,
                            doclat: np.float32,
                            doclon: np.float32  }   )

print "CMS Doctors"
print "Shape Before"
n = docs.shape[0]
print docs.shape
docs.dropna(inplace=True)   # remove NA rows -> causes error in pairwise_dist
print "Shape After dropna"
print docs.shape
print "difference: %d" % (n - docs.shape[0])

#print docs.iloc[10,:]  # Dr. 10 is in Puerto Rico...

# Load City File
cityfile = '../big_wiki_cities.csv'
cname = 'City'
citylat = 'Lat'
citylon = 'Lon'
maxrows = 114      # number of rows to read; use 2010 pop > 200k as basis
                   # last should be Montgomery AL
#maxrows=5         # Top 5 cities- NY, LA, etc.

cities = pd.read_csv(cityfile, sep=';', 
                    usecols=[
                            #cname,
                            citylat, 
                            citylon], 
                    nrows=maxrows,
                    dtype={ #cname: str,
                            citylat: np.float32,
                            citylon: np.float32 } )

print
print "# of cities (maxrows): %d" % maxrows
print cities.head()
print
print cities.tail()

# do distances
D = pairwise_distances( docs[[doclat, doclon]], 
                        #cities[[citylat, citylon]].head(), # test w/ only "big" cities
                        cities,
                        metric=haversine,
                        n_jobs=-1 )


# take min AND argmin of rows
mini = np.argmin(D, 1)   # index of mins -> city index (+1 ?)
mind = D[ xrange(D.shape[0]), mini ] 
#mind = np.zeros(len(mini), dtype=np.float32)   # trying explicit copy
#for i in xrange(len(mini)):     
#    mind[i] = D[i, mini[i]]

print "Distance Matrix:"
print D.shape

del D   # don't need Distance matrix anymore
# TODO: call gc.collect() ???

# more debug
print "mini last:\t" + str(mini[-1])
print "mind last:\t" + str(mind[-1])
print "docs.shape" + str(docs.shape)
print "mini.shape" + str(mini.shape)
print "mind.shape" + str(mind.shape)

# append columns to Dr. Data
#test = pd.Series(np.argmin(D,1), dtype=np.uint16, name='testind')
#print "test mini tail"
#print test.tail()

docs['cityIndex200k'] = pd.Series(mini, index=docs.index, dtype=np.uint16)
del mini

print "added mini col"
print docs.shape

docs['cityDist200k'] = pd.Series(mind, index=docs.index, dtype=np.float32)
del mind

print "added mind col"
print docs.shape

print docs.tail()

print "pre-save"
print docs.shape
# store as CSV w/ distance (km) and argmin as ref to city
docs.to_csv('doc_cities_TEST.csv', sep=';', index=False)

print "post-save"
print docs.shape
