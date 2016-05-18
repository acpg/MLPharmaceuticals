import re
import string
from pyzipcode import ZipCodeDatabase

inputFile =  'medilexFINAL.csv'
outputFile = 'medilexFINAL_ZIPS.csv'

zcdb = ZipCodeDatabase()

headers = 'Company;Zip;Lon;Lat;City;State\n' # column names

zip_errors = 0  # count exceptions (missing zips)
n_lines = 0     # init here, so we don't lose it after 'with'

with open(inputFile, 'r') as f, open(outputFile, 'w') as out_file:
    
    lines = f.readlines()
    n_lines = len(lines)
    print '# lines: %d' % n_lines

    out_file.write(headers) # first row of file

    for l in lines:

        fields = l.split(';')
        name = re.sub('\s+', ' ', fields[0].strip())    # strip end spaces, then compress inner spaces
        zipcode = fields[1].strip()
        #print "*" + zipcode + "*"      # check for hidden whitespace :)
       
        # medilex zips are already 5 digits
        #if len(zipcode) > 5:       # truncate 9-digit zips
        #    zipcode = zipcode[0:5]
        
        try:
            zc = zcdb[zipcode]
            lat =   zc.latitude
            lon =   zc.longitude
            city =  zc.city
            state = zc.state
        except IndexError:
            zc    = ''
            lat   = ''
            lon   = ''
            city  = ''
            state = ''

            print name + " " + zipcode  # print errors
            zip_errors += 1

        line =  name     + ';'
        line += zipcode  + ';'
        line += str(lon) + ';'
        line += str(lat) + ';'
        line += city     + ';'
        line += state    + '\n'
    
	out_file.write(line)

print
print "Missing Zips:\t%d"   % zip_errors
print "Total Lines:\t%d"    % n_lines
print "Pct. Error:\t%.2f"     % (float(zip_errors) / n_lines)
print
