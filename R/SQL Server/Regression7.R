
rm(list=ls(all=TRUE))

currency <- 1
windowsize <- 6
forecaststeps <- 1


library(odbc)
library(ggplot2)
require(lubridate)
library(digest)
library(lightgbm)
#library(plotly)

con <- DBI::dbConnect(odbc::odbc(), 
         Driver = "SQL Server", 
         Server = "localhost\\SQLEXPRESS", 
         Database = "CurrencyStrength2", 
         Trusted_Connection = "True")

DBI::dbListTables(con, table_name = "Strength%")

DBI::dbListFields(con, "Strength")

data <- DBI::dbReadTable(con, "Strength")
#View(data)

#data2 <- with(data,data[hour(Zeit)==0&minute(Zeit)==0,])
#data2 <- with(data,data[month(Zeit)==8,])
#data2 <- with(data,data[month(Zeit)==8&day(Zeit)==1&hour(Zeit)==3,])
#data2 <- with(data,data[month(Zeit)==8&day(Zeit)<=3&hour(Zeit)<24,])
#data2 <- data
data2 <- with(data,data[minute(Zeit)==59,])
#rownames(data2) <- NULL

varbase <- 1000
rcount <- nrow(data2)
ccount <- (windowsize*8)+1
data3 <- data.frame(matrix(0, ncol=ccount, nrow=rcount))

cnames <- c("Hour")
rindex <- 2
for(z in (1:8))
{
  for(zz in (1:windowsize))
  {
    cnames[rindex] <- paste0("I",(z*varbase)+zz)
    rindex <- rindex+1
  }
}
colnames(data3) <- cnames
data3[,1] <- -1

lastrowhash <- ""
dest <- 1
lastrows <- data.frame(matrix(0, ncol=8, nrow=windowsize+1))
targets <- data.frame(matrix(0, ncol=8, nrow=1))
for(z in (1:rcount))
{
  dest <- z
  rowhash <- digest(data2[z,3:10,drop=TRUE])
  if(rowhash!=lastrowhash)
  {
    for(a in (1:8))
    {
      for(b in (windowsize:1))
      {
        lastrows[b+1,a] <- lastrows[b,a]
      }
      lastrows[1,a] <- data2[z,a+2]
      targetindex <- (z+(forecaststeps-1))
      if(targetindex>rcount)
        targetindex <- rcount
      targets[1,a] <- data2[targetindex,a+2]
    }
    if(z>=windowsize)
    {
      data3[dest,1] <- hour(data2[z,2])

      for(zz in (1:8))
      {
        for(c in 1:windowsize)
        {
          data3[dest,(zz*windowsize)-(c-2)] <- lastrows[c,zz]-lastrows[(windowsize+1),zz]
          #data3[dest,(zz*windowsize)-(c-2)] <- lastrows[c,zz]
        }
        targetdiff <- targets[1,zz]-lastrows[2,zz]
        if(targetdiff>=100|targetdiff<=-100)
        {
          if(targetdiff>=100)
            targetdiff <- 1
          else
            targetdiff <- -1
            
        }
        else
          targetdiff <- 0

        data3[dest,(zz*windowsize)-(1-2)] <- targetdiff

        
        # if(data3[dest,(zz*windowsize)-(1-2)]-data3[dest,(zz*windowsize)-(2-2)]>=0)
        #   data3[dest,(zz*windowsize)-(1-2)] <- 1
        # else
        #   data3[dest,(zz*windowsize)-(1-2)] <- (-1)
        
        #data3[dest,(zz*windowsize)+1] <- lastrows[1,zz]-lastrows[(windowsize+1),zz]
        #data3[dest,(zz*windowsize)] <- lastrows[2,zz]-lastrows[(windowsize+1),zz]
        #data3[dest,(zz*windowsize)-1] <- lastrows[3,zz]-lastrows[(windowsize+1),zz]
        #data3[dest,(zz*windowsize)-2] <- lastrows[4,zz]-lastrows[(windowsize+1),zz]
        #data3[dest,(zz*windowsize)-3] <- lastrows[5,zz]-lastrows[(windowsize+1),zz]
        #data3[dest,(zz*windowsize)-4] <- lastrows[6,zz]-lastrows[(windowsize+1),zz]
      }
            
      #dest <- dest+1
    }
  }
  lastrowhash <<- rowhash
}
data4 <- with(data3,data3[Hour>-1,])
rownames(data4) <- c()
#data4[,13] <- data4[,13]+1000

#library(corrplot)
#corrplot(cor(data4), method = "square")

train_split <- as.integer(floor(nrow(data4)*0.75))

remrows <- c(0)
remindex <- 1
for(z in (1:8))
{
  if(z!=currency)
  {
    remrows[remindex] <- (windowsize*z)+1
    remindex <- remindex+1
  }
}
data4 <- data4[,-remrows]

traindata <- data4[(1:train_split),]
testdata <- data4[-(1:train_split),]

labelindex <- (((windowsize-1)*currency)+2)

traindata2 <- as.matrix(traindata[,-c((labelindex))])
#traindata2 <- as.matrix(traindata[,1:6])
testdata2 <- as.matrix(testdata[,-c((labelindex))])
#testdata2 <- as.matrix(testdata[,1:6])

dtrain <- lgb.Dataset(data=traindata2,label=traindata[[labelindex]])
dtest <- lgb.Dataset.create.valid(dtrain,data=testdata2,label=testdata[[labelindex]])

valids <- list(train=dtrain,test=dtest)

# params <- list(
#   boosting_type = "gbdt",
#   objective = "regression",
#   metric = c("l2","l1"),
#   num_leaves = 31,
#   learning_rate = 0.05,
#   feature_fraction = 0.9,
#   bagging_fraction = 0.8,
#   bagging_freq = 5,
#   verbose = 0)
# model <- lgb.train(params,
#                    dtrain,
#                    20,
#                    valids,
#                    early_stopping_rounds = 5)

params <- list(objective = "regression", categorical_feature = c(0), ignore_column = c())
model <- lgb.train(params=params,data=dtrain,valids=valids)


y_pred <- predict(model,testdata2)
##y_pred = gbm.predict(X_test, num_iteration=gbm.best_iteration)

label = getinfo(dtest,"label")


diffresult <- c(0)
diffresult2 <- c(0)
hours <- c(1:24)
hours[1:24] <- 0
for(x in (1:nrow(testdata)))
{
  diff1 <- testdata[x,labelindex]-testdata[x,labelindex-1]
  diff2 <- y_pred[x]-testdata[x,labelindex-1]
  diffresult[x] <- 0
  #if((diff1>=0&&diff2>=0)|(diff1<0&&diff2<0))
  if((y_pred[x]>=0.01&label[x]==1)|(y_pred[x]<=-0.01&label[x]==-1))
  {
    diffresult[x] <- 1
    hours[testdata[x,1]+1] <- hours[testdata[x,1]+1]+1
  }
  else
  {
    if((y_pred[x]>=0.01&label[x]==-1)|(y_pred[x]<=-0.01&label[x]==1))
      hours[testdata[x,1]+1] <- hours[testdata[x,1]+1]-1
  }
  diffresult2[x] <- 0
  if(y_pred[x]>=0.4|y_pred[x]<=-0.4)
  {
    if(label[x]==1&y_pred[x]>0)
      diffresult2[x] <- 1
    if(label[x]==-1&y_pred[x]<0)
      diffresult2[x] <- 1
  }
  else
    diffresult2[x] <- -1
}
a <- table(diffresult)
a[names(a)==1]

a <- table(diffresult2)
a[names(a)==1]



linesize <- 0.8
alpha <- 1


hoursframe <- data.frame(hours)
p3 <- ggplot(hoursframe, aes(x=as.numeric(row.names(hoursframe))-1,y=hours)) + 
  scale_x_continuous(breaks = seq(0, 23, 1), minor_breaks = seq(0, 23, 1)) + 
  labs(title="Forex Currency Strength", subtitle=paste("Aug 2018 - Jan 2019 | SQL Database with 2.2 Mio M1 Values | USD green | EUR blue | GBP pink | JPY brown | CHF black | CAD violet | AUD orange | NZD gray |", date()), caption=NULL, x = "Time", y = "Range 1/1000 %") +
  #geom_line(aes(y=y_pred),colour='mediumseagreen',size=linesize,alpha=alpha) +
  #geom_line(aes(y=label),colour='dodgerblue',size=linesize,alpha=alpha) + 
  geom_line(aes(y=hoursframe$hours),colour='dodgerblue',size=linesize,alpha=alpha) +
  theme(plot.subtitle=element_text(size=rel(0.8)))

print(p3)



