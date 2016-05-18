# Import the libraries we will be using
import numpy as np
import pandas as pd
import re
import scipy

#Import tools to analyze data
from sklearn.cross_validation import train_test_split
from sklearn import linear_model
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import PolynomialFeatures
from sklearn.svm import SVR
from sklearn.ensemble import AdaBoostClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.cross_validation import KFold
from sklearn.grid_search import GridSearchCV
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import AdaBoostClassifier
from sklearn.metrics import roc_curve, auc


#Function to preprocess data ( Categorical variables )
def pre_proc(data, list_dummy):
    #Creating Dummy variables Nature',
    for field in list_dummy:
        print field
        for value in data[field].unique()[0:-1]:
            data[field + "_" + str(value)] = pd.Series(data[field] == str(value), dtype=int)
        data = data.drop([field], axis=1)
    ########
    data = data.replace('',np.nan, regex=True)
    data = data.astype(float)
    return data    

#Function to create the models we will use to predict Binary Target
def cross_validation(x_train,y_train, n_folds=3 ):
    # DB received is the training set
    
    #Heare are the models you want to use. As default there are three. 
    models = {'logreg': LogisticRegression(), 'dectree': DecisionTreeClassifier(), 'rf':RandomForestClassifier()}
    #Hyperparameters of the models 
    params = {'logreg':{'C':[10**i for i in range(-2, 2)], 'penalty':['l1', 'l2']},      
              'dectree':{'min_samples_leaf':[50, 100, 500, 1000], 'criterion':['entropy']} ,
              'rf':{'n_estimators':[100, 200, 500, 1000], 'criterion':['entropy']}}

    kfolds = KFold(x_train.shape[0], n_folds = n_folds)
    
    best_models = {}
    for classifier in models.keys():
        
        best_models[classifier] = GridSearchCV(models[classifier], params[classifier], cv = kfolds, scoring = 'roc_auc') 
        best_models[classifier].fit(x_train, y_train)   

    #AdaBoost    
    best_models['ada']= AdaBoostClassifier()
    best_models['ada'].fit(x_train, y_train)    
    return best_models

#Load DataSet with the features and target Variable in US Dollars 
df=pd.read_csv("NPI_CMS_AMA_dist_doctors.csv")

#Columns you want to use in the model
usecols=[ "USTrained", "USD","YOB", "RGender_Code", "Year","PresentEmployment",
          "CityDistance","Gini Index",'Median value', "MedSchoolYOG"]
   
#Select columns of the model
df=df[usecols]

#List of categorical variables used in the model         
list_dummy=[ "PresentEmployment"]  
         
#Cast to string categorical variables.          
for element in list_dummy:      
    df[element] = df[element].astype(str)

#Convert Sex to (0,1)
df['RGender_Code'].replace(['F','M'],[1,0],inplace=True)

#Make dummy categorical
df= pre_proc(df,list_dummy)
#Impute empty values 
df= df.fillna(df.mean())


#Create binary target variable 
Y=df['USD'].copy()
Y[Y<100]=0
Y[Y>=100]=1

#Split in train and test set
X_train, X_test, Y_train, Y_test = train_test_split(df.ix[:, df.columns != 'USD']
                                                    , Y, train_size=0.80)


#Cross Validation function
clf_models=cross_validation(X_train,Y_train, n_folds=3 )

#Select a model from cross validation
clf= clf_models['dectree']
#####Classification performance Metrics
########
fpr, tpr, thresholds = roc_curve(Y_test, clf.predict(X_test))
#Auc
aucScore= auc(fpr, tpr)
#Recall
Y_predicted=clf.predict(X_test)
aux=Y_test[(Y_predicted==1)&(Y_test==1)]
aux2= Y_test[(Y_predicted==0)&(Y_test==1)]
recall= sum(aux)/(sum(aux)+sum(aux2))
#Accuracy
accuracy= clf.score(X_test, Y_test)




  
