library(ggplot2)
library(plyr)

#-----------------------------------------------

data <- read.csv('../data/31days.csv', header = TRUE) 

data2 <- read.csv("../data/62days.csv", header = TRUE) 

data <- as.data.frame (data2)

t <- c('NCA','NCA', 'NCA', 'NCA', 'NCA', 'NCA', 'SCAN','SCAN','SCAN','SCAN', 'WOSCAN','WOSCAN','WOSCAN','WOSCAN')
f <- c('S08000020','S08000022', 'S08000025', 'S08000026', 'S08000030', 'S08000028', 'S08000016','S08000017',
       'S08000029','S08000024', 'S08000015','S08000019','S08000031','S08000032')

data$HB <- mapvalues(data$HB,f,t)

data_new <- aggregate(cbind(NumberOfEligibleReferrals62DayStandard=data$NumberOfEligibleReferrals62DayStandard,
                            NumberOfEligibleReferralsTreatedWithin62Days=data$NumberOfEligibleReferralsTreatedWithin62Days,
                            PopSize = data$PopSize), 
                      by=list( Quarter = data$Quarter, Date=data$Date, HB=data$HB, CancerType = data$CancerType,
                               Pandemic=data$Pandemic, JustPandemic=data$JustPandemic, Pandemic_cat=data$Pandemic_cat), FUN=sum)

regions = c('WOSCAN', 'SCAN', 'NCA')
cancers = c('Breast', 'Lung', 'Urological')

for (reg in regions){
  for (ct in cancers){
    data <- subset(subset(data_new, CancerType==ct), HB==reg)
    
    logLE <- log(data$PopSize)# -> add for population size
    
    family1 = "poisson"
    
    data$DateSquared <- (data$Date)^2
    
    #--------- log-link is chosen by default in Poisson distribution. #--------- 
    
    mod.1 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date  , data = data, family=family1 )
    mod.2 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date +DateSquared , data = data, family=family1 )
    mod.3 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date +JustPandemic , data = data, family=family1 )
    mod.6 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date +DateSquared + JustPandemic , data = data, family=family1 )
    mod.4 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date +Pandemic_cat + JustPandemic , data = data, family=family1 )
    mod.5 <- glm( NumberOfEligibleReferrals62DayStandard ~  offset(logLE) + Date +DateSquared +Pandemic_cat+ JustPandemic , data = data, family=family1 )
    
    print(summary(mod.1))
    #print(summary(mod.2))
    #print(summary(mod.3))
    #print(summary(mod.4))
    #print(summary(mod.5))
    #print(summary(mod.6))
    
    coef(mod.1)
    
    mod.1.predict <- predict( mod.1, type = "response" ) # to generate estimated number of referrals
    mod.2.predict <- predict( mod.2, type = "response" ) # to generate estimated number of referrals
    mod.3.predict <- predict( mod.3, type = "response" ) # to generate estimated number of referrals
    mod.4.predict <- predict( mod.4, type = "response" ) # to generate estimated number of referrals
    mod.5.predict <- predict( mod.5, type = "response" ) # to generate estimated number of referrals
    mod.6.predict <- predict( mod.6, type = "response" ) # to generate estimated number of referrals
    
    AIC(mod.1)
    
    BIC(mod.1)
    
    ci <- confint(mod.1)
    ci
    
    results <- summary(mod.1)$coefficients
    results <- cbind(results, '2.5%'=ci[,1])
    results <- cbind(results, '97.5%'=ci[,2])
    results <- cbind(results, 'AIC'=AIC(mod.1))
    results <- cbind(results, 'BIC'=BIC(mod.1))
    write.csv(results,paste('results/62_eligible_',reg,'_',ct,'.csv'))
    
    #--------- Extending the data by adding two new columns which show fitted data
    
    data <- cbind( data, 'fitted1'=mod.1.predict/data$PopSize )
    data <- cbind( data, 'fitted2'=mod.2.predict/data$PopSize )
    data <- cbind( data, 'fitted3'=mod.3.predict/data$PopSize )
    data <- cbind( data, 'fitted4'=mod.4.predict/data$PopSize )
    data <- cbind( data, 'fitted5'=mod.5.predict/data$PopSize )
    data <- cbind( data, 'fitted6'=mod.6.predict/data$PopSize )
    #data <- cbind( data, mod.1.predict )
    
    data$rates <- data$NumberOfEligibleReferrals62DayStandard / data$PopSize
    
    #--------- Let's try to make a plot showing fitted data #--------- 
    
    data_plot <- data
    plot_name <- paste('Nr of 62 day eligible referrals in',reg,'for',ct,'cancer')
    models <- c()
    colors <- c()
    
    png(file=paste('results/62_eligible_',reg,'_',ct,'.png'),width=600, height=350)
    plot(data_plot$Date, data_plot$rates,
         main=plot_name,
         ylab="rate of referrals", xlab='time',
         type="l",
         col="black", xaxt='n',
         cex.lab=1.5, cex.axis=1.5, cex.main=1.5, cex.sub=1.5) 
    axis(1, at=data_plot$Date, labels=data_plot$Quarter)
    if(all(summary(mod.1)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted1, col='blue')
      models <- c(models, 'fitted model 1')
      colors <- c(colors, 'blue')}
    if(all(summary(mod.2)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted2, col='red')
      models <- c(models, 'fitted model 2')
      colors <- c(colors, 'red')}
    if(all(summary(mod.3)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted3, col='orange')
      models <- c(models, 'fitted model 3')
      colors <- c(colors, 'orange')}
    if(all(summary(mod.4)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted4, col='green')
      models <- c(models, 'fitted model 4')
      colors <- c(colors, 'green')}
    if(all(summary(mod.5)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted5, col='brown')
      models <- c(models, 'fitted model 5')
      colors <- c(colors, 'brown')}
    if(all(summary(mod.6)$coefficients[,4]<0.05)==TRUE){
      lines(data_plot$Date, data_plot$fitted6, col='yellow')
      models <- c(models, 'fitted model 6')
      colors <- c(colors, 'yellow')}
    legend("topleft",
           c("actual",models),
           fill=c("black",colors))
    dev.off()
  }
}

