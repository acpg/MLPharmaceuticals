### R code from vignette source 'descriptives3.Rnw'

###################################################
### code chunk number 1: descriptives3.Rnw:22-44
###################################################
options(stringsAsFactors = FALSE)
options("xtable.include.rownames"=FALSE)
options("xtable.caption.placement"='top')
options("datatable.showProgress"=FALSE)
library(xtable)
library(plyr)
library(ff)
library(ggplot2)
library(reshape2)
library(data.table)
library(glmnet)
library(ada)
library(l2boost)
library(Matrix)
library(e1071)
library(rpart)
library(randomForest)
library(ROCR)
library(gbm)
set.seed(1)
trim <- function (x) gsub("^\\s+|\\s+$", "", x)
#setwd("~/Google Drive/2016 1Spring/Machine Learning/ML Project")


###################################################
### code chunk number 2: descriptives3.Rnw:46-56
###################################################
data <- fread('Clean Data/payments_CMS.csv', sep=',', header=TRUE)
data <- data[USD!=0]
data[,log.USD:=log(USD)]
aux <- rbind(summary(data[,USD]),summary(data[,log.USD]))
print(xtable(aux,caption='Summary of Response Variable'))
rm(aux)


###################################################
### code chunk number 3: descriptives3.Rnw:62-64
###################################################
g <- ggplot(data, aes(x=log.USD)) + geom_histogram(colour = "darkgreen", fill = "white", binwidth = 0.4) + theme_bw() +facet_wrap(~Year)
ggsave('Plots/plot_pymt_hist.pdf',g,width=8,height=4)


###################################################
### code chunk number 5: descriptives3.Rnw:94-106
###################################################
drs <- fread('Clean Data/NPI_CMS_Chen_dist_doctors.csv', sep=',', header=TRUE, colClasses = 'character', na.strings='NA')
drs <- drs[sample(nrow(drs)),] #shuffle
drs[,MedSchoolYOG:=as.numeric(drs[,MedSchoolYOG])]
drs[,cityDist200k:=as.numeric(drs[,cityDist200k])]
drs[,Grouping:=factor(drs[,Grouping],levels=unique(drs[,Grouping]))]
drs[,Taxonomy_Code:=factor(drs[,Taxonomy_Code],levels=unique(drs[,Taxonomy_Code]))]
set(drs,which(!drs[,RCountry_Code]=='US'),'RCountry_Code','INTL')
drs[,RCountry_Code:=factor(drs[,RCountry_Code],levels=unique(drs[,RCountry_Code]))]
drs[,RCredential:=gsub('\\W','',drs[,RCredential])]
drs[,RCredential:=factor(drs[,RCredential],levels=unique(drs[,RCredential]))]
drs[,RGender_Code:=factor(drs[,RGender_Code],levels=unique(drs[,RGender_Code]))]
drs[,PresentEmployment:=factor(drs[,PresentEmployment],levels=unique(drs[,PresentEmployment]))]


###################################################
### code chunk number 6: descriptives3.Rnw:108-111
###################################################
aux <- data.frame(Variable=c('Original','Matched'),NPPES=c(3631242,length(unique(drs[,NPI]))),CMS=c(684915,length(unique(drs[,Physician_Profile_ID]))),AMA=c(839712,sum(!is.na(drs[,ResearchID]))))
print(xtable(aux,caption='Number of Observations',label='data_obs',digits=0))
rm(aux)



###################################################
### code chunk number 8: descriptives3.Rnw:177-190
###################################################
pay_dr <- merge(drs,data,by.x='Physician_Profile_ID',by.y='Physician_ID')
X <- sparse.model.matrix(~Taxonomy_Code,pay_dr)
itrain <- 1:floor(.8*nrow(pay_dr))
itest <- (floor(.8*nrow(pay_dr))+1):nrow(pay_dr)
myglm <- glmnet(X[itrain,],as.matrix(pay_dr[itrain,log.USD]),lambda=0)
Yfit <- predict(myglm,X[itest,])
cat(mean((Yfit-pay_dr[itest,log.USD])^2))
cat('\n  in log US dollars.\n')
#print(xtable(data.frame(myglm$beta[,1]),caption='Baseline Coefficients'),size='tiny', include.rownames=TRUE)
aux <- data.frame(Yfit=Yfit[,1],Y=pay_dr[itest,log.USD])
aux <- melt(aux)
g <- ggplot(aux, aes(x=value,fill=variable)) + geom_density(adjust=5,alpha=.5)
ggsave('Plots/plot_baseline_density.pdf',g,width=6,height=4)


###################################################
### code chunk number 9: descriptives3.Rnw:205-214
###################################################
pay_drs <- subset(pay_dr,select=c(Grouping,Year,RGender_Code,MedSchoolYOG,USTrained,cityDist200k,log.USD,USD))
pay_drs <- pay_drs[complete.cases(pay_drs),]
X <- sparse.model.matrix(~Grouping+Year+RGender_Code+MedSchoolYOG+USTrained+cityDist200k,pay_drs)
itrain <- 1:floor(.8*nrow(pay_drs))
itest <- (floor(.8*nrow(pay_drs))+1):nrow(pay_drs)
myglm <- glmnet(X[itrain,],as.matrix(pay_drs[itrain,log.USD]),family="gaussian",alpha=1,lambda.min.ratio=.0000001) # lasso
pdf('Plots/plot_lasso.pdf',width=10,height=5)
plot(myglm)
dev.off()


###################################################
### code chunk number 10: descriptives3.Rnw:216-241
###################################################
Ytrain.fit <- predict(myglm,X[itrain,])
Ytest.fit <- predict(myglm,X[itest,])
Etrain <- apply(Ytrain.fit, 2, function(x) mean(abs(x-pay_drs[itrain,log.USD])))
Etest <- apply(Ytest.fit, 2, function(x) mean(abs(x-pay_drs[itest,log.USD])))
aux <- data.table(lambda=myglm$lambda,Etrain=Etrain,Etest=Etest)
aux <- melt(aux,'lambda')
g <- ggplot(aux,aes(x=lambda,y=value,colour=variable))+geom_line()+theme_bw()+scale_x_reverse()
ggsave('Plots/plot_lasso_error.pdf',g,width=10,height=5)
rm(aux)
ll <- which(Etest==min(Etest))
cat('We get a mean squared error of ')
cat(mean((Ytest.fit[,ll]-pay_drs[itest,log.USD])^2))
cat(' with ')
cat(myglm$df[ll])
cat(' non-zero coefficients and the deviance explained is ')
cat(myglm$dev.ratio[ll])
cat('.\n ') 
print(xtable(data.frame(myglm$beta[,ll]),caption='Lasso Coefficients'), size='tiny', include.rownames=TRUE)
aux <- data.frame(Yfit=Ytest.fit[,ll],Y=pay_dr[itest,log.USD])
aux <- melt(aux)
g <- ggplot(aux, aes(x=value,fill=variable)) + geom_density(adjust=5,alpha=.5)
ggsave('Plots/plot_lasso_density.pdf',g,width=5,height=5)
aux <- data.frame(Ytest.fit=Ytest.fit[,ll],Ytest=pay_dr[itest,log.USD])
g <- ggplot(aux,aes(x=Ytest,y=Ytest.fit)) + geom_point()
ggsave('Plots/plot_lasso_train.pdf',g,width=6,height=4)


###################################################
### code chunk number 11: descriptives3.Rnw:272-276
###################################################
myglm <- glmnet(X[itrain,],as.matrix(pay_drs[itrain,log.USD]),family="gaussian",alpha=0,lambda.min.ratio=.0000001) # ridge
pdf('Plots/plot_ridge.pdf',width=10,height=5)
plot(myglm)
dev.off()


###################################################
### code chunk number 12: descriptives3.Rnw:278-301
###################################################
Ytrain.fit <- predict(myglm,X[itrain,])
Ytest.fit <- predict(myglm,X[itest,])
Etrain <- apply(Ytrain.fit, 2, function(x) mean((x-pay_drs[itrain,log.USD])^2))
Etest <- apply(Ytest.fit, 2, function(x) mean((x-pay_drs[itest,log.USD])^2))
aux <- data.table(lambda=myglm$lambda,Etrain=Etrain,Etest=Etest)
aux <- melt(aux,'lambda')
g <- ggplot(aux,aes(x=lambda,y=value,colour=variable))+geom_line()+theme_bw()+scale_x_reverse()
ggsave('Plots/plot_ridge_error.pdf',g,width=10,height=5)
rm(aux)
cat('We get a mean squared error of ')
ll <- which(Etest==min(Etest))
cat(mean((Ytest.fit[,ll]-pay_drs[itest,log.USD])^2))
cat(' and the deviance explained is ')
cat(myglm$dev.ratio[ll])
cat('.\n ') 
print(xtable(data.frame(myglm$beta[,ll]),caption='Ridge Coefficients'),size='tiny', include.rownames=TRUE)
aux <- data.frame(Yfit=Ytest.fit[,ll],Y=pay_dr[itest,log.USD])
aux <- melt(aux)
g <- ggplot(aux, aes(x=value,fill=variable)) + geom_density(adjust=5,alpha=.5)
ggsave('Plots/plot_ridge_density.pdf',g,width=5,height=5)
aux <- data.frame(Ytest.fit=Ytest.fit[,ll],Ytest=pay_dr[itest,log.USD])
g <- ggplot(aux,aes(x=Ytest,y=Ytest.fit)) + geom_point()
ggsave('Plots/plot_ridge_train.pdf',g,width=5,height=5)


###################################################
### code chunk number 13: descriptives3.Rnw:335-341
###################################################
myl2boost <- l2boost(X[itrain,],as.matrix(pay_drs[itrain,log.USD]),M=8,nu=.0000001) # L2 boost
Ytrain.fit <- predict(myl2boost,X[itrain,])
Ytest.fit <- predict(myl2boost,X[itest,])
pdf('Plots/plot_l2boost.pdf',width=10,height=5)
plot(myl2boost)
dev.off()


###################################################
### code chunk number 14: descriptives3.Rnw:343-350
###################################################
cat('Mean squared error ') 
cat(mean((Ytest.fit$yhat-pay_drs[itest,log.USD])^2))
cat('.\n ') 
#cat(mean((Ytrain.fit$yhat-pay_drs[itrain,log.USD])^2))
aux <- data.frame(Ytest.fit=Ytest.fit$yhat,Ytest=pay_drs[itest,log.USD])
g <- ggplot(aux,aes(x=Ytest,y=Ytest.fit)) + geom_point()
ggsave('Plots/plot_l2_train.pdf',g,width=5,height=5)


###################################################
### code chunk number 15: descriptives3.Rnw:366-370
###################################################
drs[,IPay:= '<=500']
set(drs,which(drs[,Physician_Profile_ID]%in%data[USD>500,Physician_ID]),'IPay','>500')


###################################################
### code chunk number 16: descriptives3.Rnw:372-376
###################################################
#aux <- drs[,.N,by=.(IPay2013,IPay2014)]
aux <- drs[,.(Total=.N,Complete=sum(!is.na(Physician_Profile_ID)&!is.na(ResearchID))),by=.(IPay)]
print(xtable(aux,caption='Number of Doctors who Received Payments',label='N_drs_dummy',digits=0))
rm(aux)


###################################################
### code chunk number 17: descriptives3.Rnw:383-391
###################################################
docs <- subset(drs,select=c(Physician_Profile_ID,Taxonomy_Code,Grouping,RGender_Code,MedSchoolYOG,RCountry_Code,RCredential,PresentEmployment,cityDist200k))
docs[,IPay:= '<=500']
set(docs,which(docs[,Physician_Profile_ID]%in%data[USD>500,Physician_ID]),'IPay','>500')
docs <- docs[complete.cases(docs),]
docs <- data.frame(docs)
itrain <- 1:floor(.8*nrow(docs))
itest <- (floor(.8*nrow(docs))+1):nrow(docs)
mytree <- rpart(IPay~Taxonomy_Code,data=docs[itrain,],control=rpart.control(minsplit=5, minbucket=1, cp=0.001))


###################################################
### code chunk number 18: descriptives3.Rnw:393-400
###################################################
Ytrain.fit <- as.character(predict(mytree,docs[itrain,],type='class'))
Ytest.fit <- as.character(predict(mytree, docs[itest,],type='class'))
cat(' We get percentage correct ') 
cat(mean(Ytest.fit==docs$IPay[itest])*100)
cat('\\% on testing data and ') 
cat(mean(Ytrain.fit==docs$IPay[itrain])*100)
cat('\\% on training data. ') 


###################################################
### code chunk number 19: descriptives3.Rnw:404-408
###################################################
mytree <- rpart(IPay~Taxonomy_Code+RGender_Code+MedSchoolYOG+RCountry_Code+PresentEmployment+cityDist200k,data=docs[itrain,],control=rpart.control(minsplit=5, minbucket=1, cp=0.001))
plot(mytree)
#text(mytree, use.n=TRUE)
rsq.rpart(mytree)


###################################################
### code chunk number 20: descriptives3.Rnw:410-417
###################################################
Ytrain.fit <- as.character(predict(mytree,docs[itrain,],type='class'))
Ytest.fit <- as.character(predict(mytree, docs[itest,],type='class'))
cat(' We get percentage correct ') 
cat(mean(Ytest.fit==docs$IPay[itest])*100)
cat('\\% on testing data and ') 
cat(mean(Ytrain.fit==docs$IPay[itrain])*100)
cat('\\% on training data. ') 


###################################################
### code chunk number 21: descriptives3.Rnw:420-429
###################################################
prob <- predict(mytree, newdata=docs[itest,], type="prob")[,2]
pred <- prediction(prob, docs$IPay[itest])
perf <- performance(pred, measure = "tpr", x.measure = "fpr")
auc <- performance(pred, measure = "auc")
auc <- auc@y.values[[1]]
roc.data <- data.frame(fpr=unlist(perf@x.values),tpr=unlist(perf@y.values),model="GLM")
g <- ggplot(roc.data, aes(x=fpr, ymin=0, ymax=tpr)) + geom_ribbon(alpha=0.2) + geom_line(aes(y=tpr)) +  ggtitle(paste0("ROC Curve w/ AUC=", auc))
cat('\\begin{figure}[ht]\n \\centering\n \\caption{ROC Curve with AUC=',auc,'}\n')
ggsave('Plots/plot_ROC.pdf',g,width=6,height=4)


###################################################
### code chunk number 22: descriptives3.Rnw:437-446
###################################################
docs$Grouping <- as.factor(docs$Grouping)
docs$RGender_Code <- as.factor(docs$RGender_Code)
docs$RCountry_Code <- as.factor(docs$RCountry_Code)
docs$PresentEmployment <- as.factor(docs$PresentEmployment)
docs$IPay <- as.factor(docs$IPay)
mytree <- randomForest(IPay~Grouping+RGender_Code+MedSchoolYOG+PresentEmployment+cityDist200k,data=docs[itrain,], importance=TRUE, ntree=100)
pdf('Plots/plot_forest_varImpPlot.pdf',width=10,height=5)
varImpPlot(mytree)
dev.off()


###################################################
### code chunk number 23: descriptives3.Rnw:448-455
###################################################
Ytrain.fit <- as.character(predict(mytree,docs[itrain,],type='class'))
Ytest.fit <- as.character(predict(mytree, docs[itest,],type='class'))
cat('Percentage correct ') 
cat(mean(Ytest.fit==docs$IPay[itest])*100)
cat('\\% on testing data and ') 
cat(mean(Ytrain.fit==docs$IPay[itrain])*100)
cat('\\% on training data. ') 


###################################################
### code chunk number 24: descriptives3.Rnw:465-476
###################################################
prob <- predict(mytree, newdata=docs[itest,], type="prob")[,2]
pred <- prediction(prob, docs$IPay[itest])
perf <- performance(pred, measure = "tpr", x.measure = "fpr")
auc <- performance(pred, measure = "auc")
auc <- auc@y.values[[1]]
roc.data <- data.frame(fpr=unlist(perf@x.values),tpr=unlist(perf@y.values),model="GLM")
g <- ggplot(roc.data, aes(x=fpr, ymin=0, ymax=tpr)) + geom_ribbon(alpha=0.2) + geom_line(aes(y=tpr))
ggsave('Plots/plot_ROC_forest.pdf',g,width=6,height=4)


###################################################
### code chunk number 25: descriptives3.Rnw:485-502
###################################################
docs <- subset(drs,select=c(Physician_Profile_ID,Taxonomy_Code,Grouping,RGender_Code,MedSchoolYOG,RCountry_Code,RCredential,PresentEmployment,cityDist200k))
docs[,IPay:= 0]
set(docs,which(docs[,Physician_Profile_ID]%in%data[USD>500,Physician_ID]),'IPay',1)
docs <- data.frame(docs)
itrain <- 1:floor(.8*nrow(docs))
itest <- (floor(.8*nrow(docs))+1):nrow(docs)
mygbm <- gbm(IPay~Taxonomy_Code+RGender_Code+MedSchoolYOG+RCountry_Code+PresentEmployment+cityDist200k,data=docs[itrain,])
best.iter <- gbm.perf(mygbm,method="OOB")
Ytrain.fit <- predict(mygbm,docs[itrain,],best.iter,type='response')
Ytest.fit <- predict(mygbm,docs[itest,],best.iter,type='response')
aux <- data.frame(Ytrain.fit = Ytrain.fit,Ytrain = docs[itrain,'IPay'])
g <- ggplot(aux,aes(x=Ytrain,y=Ytrain.fit)) + geom_point()
ggsave('Plots/plot_gbm_train.pdf',g,width=5,height=5)
aux <- data.frame(Ytest.fit=Ytest.fit,Ytest=docs[itest,'IPay'])
g <- ggplot(aux,aes(x=Ytest,y=Ytest.fit)) + geom_point()
ggsave('Plots/plot_gbm_test.pdf',g,width=5,height=5)


###################################################
### code chunk number 26: descriptives3.Rnw:505-515
###################################################
pred <- prediction(Ytest.fit, docs$IPay[itest])
perf <- performance(pred, measure = "tpr", x.measure = "fpr")
auc <- performance(pred, measure = "auc")
auc <- auc@y.values[[1]]
roc.data <- data.frame(fpr=unlist(perf@x.values),tpr=unlist(perf@y.values),model="GLM")
g <- ggplot(roc.data, aes(x=fpr, ymin=0, ymax=tpr)) + geom_ribbon(alpha=0.2) + geom_line(aes(y=tpr))
ggsave('Plots/plot_ROC_gbm.pdf',g,width=6,height=4)


