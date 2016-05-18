setwd("~/Google Drive/2016 1Spring/Machine Learning/ML Project")
#source("~/Google Drive/2016 1Spring/Machine Learning/ML Project/Ana Files/Scripts/doctors_zips.R")
library(data.table)
states <- fread('Ana Files/Raw Data/state_table.csv', sep=',', header=TRUE, colClasses = 'character', na.strings='')
states <- states[!is.na(abbreviation)]
vars <- c(paste0('Healthcare Provider Taxonomy Code_',1:15),paste0('Healthcare Provider Primary Taxonomy Switch_',1:15))
vars <- c("NPI","Entity Type Code","Provider Last Name (Legal Name)","Provider First Name","Provider Middle Name","Provider Name Suffix Text",
          "Provider Credential Text","Provider Business Practice Location Address City Name","Provider Business Practice Location Address State Name","Provider Business Practice Location Address Postal Code","Provider Business Practice Location Address Country Code (If outside U.S.)","Provider Gender Code",vars)
data <- fread('../ML Project Data/NPPES/npidata_20050523-20160410.csv', sep=',', header=TRUE, colClasses = 'character', select = vars, na.strings='')
names(data) <- gsub(' ','_',names(data))
data <- data[Entity_Type_Code == '1'] # Physicians
data[,Entity_Type_Code:=NULL]
names(data) <- gsub('Business_Practice_Location_Address_|_\\(If_outside_U.S.\\)|_\\(Legal_Name\\)|_Text','',names(data))
data[,Provider_Last_Name:=gsub('\\W','',data[,Provider_Last_Name])]
data[,Provider_First_Name:=gsub('\\W','',data[,Provider_First_Name])]
data[,Provider_Middle_Name:=substr(gsub('\\W|0|1|4|_','',data[,Provider_Middle_Name]),1,1)]
set(data,which(data[,Provider_Middle_Name]==''),'Provider_Middle_Name',NA)
data[,Provider_Name_Suffix:=gsub('\\W','',data[,Provider_Name_Suffix])]
data[,Provider_State_Name:=gsub('\\W','',data[,Provider_State_Name])]
for(i in 1:nrow(states)){
  set(data,grep(toupper(states[i,name]),data[,Provider_State_Name]),'Provider_State_Name',toupper(states[i,abbreviation]))
}
set(data,which(!data[,Provider_State_Name] %in% toupper(states[,abbreviation])),'Provider_State_Name',NA)
rm(states)
set(data,j='Taxonomy_Code',value='')
for(i in 1:15){
  ind <- which(data[,get(paste0('Healthcare_Provider_Primary_Taxonomy_Switch_',i))]=='Y')
  set(data,ind,'Taxonomy_Code',data[ind,get(paste0('Healthcare_Provider_Taxonomy_Code_',i))])
  data[,grep(paste0('_',i,'$'),names(data)):=NULL]
}
vars <- c('Code','Grouping','Classification')
aux <- fread('Ana Files/Raw Data/nucc_taxonomy_160.csv', sep=',', header=TRUE, colClasses = 'character', select=vars, na.strings='')
data <- merge(data,aux,by.x='Taxonomy_Code',by.y='Code',all.x=TRUE)
rm(aux)
setkey(data,NPI)
vars <- c('Physician_Profile_ID','Physician_Profile_Last_Name','Physician_Profile_Middle_Name','Physician_Profile_First_Name','Physician_Profile_Suffix','Physician_Profile_City','Physician_Profile_State')
drs <- fread('../ML Project Data/CMS/PHPRFL_P011516/OP_PH_PRFL_SPLMTL_P01152016.csv', sep=',', header=TRUE, colClasses = 'character', select=vars,na.strings='')
drs[,Physician_Profile_City:=toupper(drs[,Physician_Profile_City])]
drs[,Physician_Profile_State:=toupper(drs[,Physician_Profile_State])]
drs[,Physician_Profile_Last_Name:=gsub('\\W','',drs[,Physician_Profile_Last_Name])]
drs[,Physician_Profile_First_Name:=gsub('\\W','',drs[,Physician_Profile_First_Name])]
drs[,Physician_Profile_Middle_Name:=substr(gsub('\\W','',drs[,Physician_Profile_Middle_Name]),1,1)]
set(drs,which(drs[,Physician_Profile_Middle_Name]==''),'Physician_Profile_Middle_Name',NA)
drs[,Physician_Profile_Suffix:=toupper(gsub('\\W|DDS|DR|IMD','',drs[,Physician_Profile_Suffix]))]
set(drs,which(drs[,Physician_Profile_Suffix]==''),'Physician_Profile_Suffix',NA)
drs <- merge(data,drs,by.x=c('Provider_Last_Name','Provider_First_Name','Provider_Middle_Name','Provider_Name_Suffix','Provider_City_Name','Provider_State_Name'),
             by.y=c('Physician_Profile_Last_Name','Physician_Profile_First_Name','Physician_Profile_Middle_Name','Physician_Profile_Suffix','Physician_Profile_City','Physician_Profile_State'),all.x=TRUE)
rm(data)
#drs <- drs[!duplicated(drs[,Physician_Profile_ID])]
drs <- drs[!duplicated(drs[,NPI])]
setkey(drs,NPI)
drs[,Provider_Last_Name:=NULL]
drs[,Provider_Middle_Name:=NULL]
drs[,Provider_First_Name:=NULL]
names(drs) <- gsub('Provider_','R',names(drs))
set(drs,j='Rzip',value=substr(drs[,RPostal_Code],1,5))
drs[,RPostal_Code:=NULL]
# Use 2013 Census Data
zips <- fread('Ana Files/Raw Data/2013_Gaz_zcta_national.txt', header=TRUE,select=c('GEOID','INTPTLAT','INTPTLONG'),colClasses=c('GEOID'='character'),verbose=FALSE,showProgress=FALSE)
names(zips) <- c('Rzip','Rlat','Rlon')
drs <- merge(drs,zips,by='Rzip',all.x=TRUE)
# Data imputation using mean of those zip codes starting with same 3 numbers
zips.na <- unique(drs$Rzip[which(is.na(drs$Rlat) & grepl('US',drs$RCountry_Code) & drs$Rzip!='' & !grepl('^000|99999',drs$Rzip))])
# We only include those for which we know we have the first 3 numbers
zips.na <- zips.na[substr(zips.na,1,3) %in% unique(substr(zips$Rzip,1,3))]
pb <- txtProgressBar(min = 0, max = length(zips.na), style = 3)
i <- 0
for(z in zips.na){
  pre.z <- substr(z,1,3)
  aux <- zips[grep(paste0('^',pre.z),zips[,Rzip]),]
  if(nrow(aux) > 0){
    drs[drs$Rzip == z, Rlat:= aux[,mean(Rlat)]]
    drs[drs$Rzip == z, Rlon:= aux[,mean(Rlon)]]
  }
  i <- i+1
  setTxtProgressBar(pb, i)
}
close(pb)
rm(aux,zips,pre.z,zips.na,z)
setkey(drs,NPI)
write.csv(drs,file='Ana Files/Clean Data/NPI_CMS_doctors.csv',row.names=FALSE)
#data <- fread('Ali Folder/DemoCensus.csv',colClasses='character')
vars <- c('NPI','ResearchID','YOB','PresentEmployment','MedSchoolYOG','USTrained')
data <- fread('../ML Project Data/QUO-126342-ILW1JV.txt', header=TRUE, sep=',', colClasses='character', select=vars)
setkey(data,NPI)
drs <- merge(drs,data,by='NPI',all.x=TRUE)
write.csv(drs,file='Ana Files/Clean Data/NPI_CMS_Chen_doctors.csv',row.names=FALSE)
data <- fread('doug files/cms2013_doc_city_distance/doc_cities_200k.csv',colClasses='character')
drs <- merge(drs,data,by='Physician_Profile_ID',all.x=TRUE)
write.csv(drs,file='Ana Files/Clean Data/NPI_CMS_Chen_dist_doctors.csv',row.names=FALSE)
