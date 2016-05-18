The files in this folder will reproduce the pharmaceutical company analysis.
By Ana Perez-Gea, Ali Limon, and Douglas Brantner
New York University

Note: make sure to change the working directory to where you want the files to be changed. Currently, it is set to reading raw data from a “Raw Data” folder and saving them in a “Clean Data” one. The analysis then reads from the “Clean Data” folder.

Data Cleaning

clean_payments.R
Takes CMS payment data and aggregates the payments per doctor per year and saves them in a new file called “payments_CMS.csv”

Merge_Demo_Census.R
This script merges the Doctor NPI and Census Data 
Input:
-Demographics data (QUO-126342-ILW1JV.txt)
-Census data (Raw Data/Census_Data.csv)
Output
- Demo-Census data (Clean Data/demoCensus.csv)


clean_drs.R
This script merges all the doctor data.
Input:
- state_table.csv a list of states initials and names to clean doctor states
- npidata_[date].csv NPPES doctor data taken as the universe
- nucc_taxonomy_160.csv taxonomy code, name and group information
- OP_PH_PRFL_SPLMTL_P01152016.csv doctor information from CMS 
- 2013_Gaz_zcta_national.txt Census Gazetteer files
- DemoCensus.csv Census 2013 Information 
- QUO-126342-ILW1JV.txt Demographic AMA data
- doc_cities_200k.csv Doctor distance to major city
Output:
NPI_CMS_Chen_dist_doctors.csv

BinaryModels.py
This script train the models for binary classification. It also output the models
with the best hyper parameters. Finally, it computes different predictive performance metrics.
Input:NPI_CMS_AMA_dist_doctors.csv
Output: Models and Metrics.




