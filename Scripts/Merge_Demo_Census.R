library(gdata)
library(stringr) 
library(dplyr)
library(plyr)
library(data.table)


#Download NPI information
#Headers that we will use for demographics information
headers = c("NPI", 'FIPSCounty',"FIPSState",'CensusTract', "CensusSuffix")
dfDem<-fread("QUO-126342-ILW1JV.txt", select= headers)
#Data of census by Tract. 
dfCensu<-fread("Raw Data/Census_Data.csv")

#Create a Tract ID for census data
dfCensu$ID<- paste(as.numeric(dfCensu$`State (FIPS)`), 
                   as.numeric(dfCensu$County), 
                   as.numeric(dfCensu$`Census Tract`), sep="_")

#Create a Tract ID for Demographics data
dfDem$Tract<-paste(as.numeric(dfDem$CensusTract), 
                 dfDem$CensusSuffix, sep="")
dfDem$ID<- paste(as.numeric(dfDem$FIPSState), 
                 as.numeric(dfDem$FIPSCounty), 
                 dfDem$Tract,
                 sep="_")

#First Join by Tract
demoCensus<-join(x=dfDem, y=dfCensu, by = "ID", type = "left", match = "first")

#Some Physicians have an erroneous tract
#Sum one (+1) for the Tract ID of Demographics (Just three iteration)
for (i in range(1,3)){
  # Do the process just for null values
  dfDem<-demoCensus[is.na(demoCensus$County)]
  #Original Data (drop na)
  dfDem<-dfDem[,1:7,with=FALSE]
  #Sum one
  dfDem$CensusSuffix<-as.numeric(dfDem$CensusSuffix)+1
  dfDem<-dfDem[!is.na(dfDem$CensusSuffix)]
  #Make the same format than census data ("0", number)
  dfDem$CensusSuffix[dfDem$CensusSuffix<10]<-paste(0,
                                                     dfDem$CensusSuffix[dfDem$CensusSuffix<10],
                                                     sep="") 
  #Create the tract ID 
  dfDem$Tract<-paste(as.numeric(dfDem$CensusTract), 
                      dfDem$CensusSuffix, sep="")
  dfDem$ID<- paste(as.numeric(dfDem$FIPSState), 
                    as.numeric(dfDem$FIPSCounty), 
                    dfDem$Tract,
                    sep="_")
 
  #Join the dataSets
  demoCensus_aux<-join(x=dfDem, y=dfCensu, by = "ID", type = "left", match = "first")  
  #Combine datasets to
  demoCensus<- rbind(demoCensus[demoCensus$County!=""],
                     demoCensus_aux[demoCensus_aux$County!=""])
}

#Export DataSet with specific features
headers = c('NPI', 'Gini Index', 'Median value', 'Median Gross Rent')

demoCensus<-subset(demoCensus, select=headers)
write.csv(demoCensus, "Clean Data/demoCensus.csv")
