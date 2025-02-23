#install packages
install.packages("GGally")
install.packages("pROC") 

#Load Libraries
library(dplyr)
library(tidyverse)
library(caret)
library(ggplot2)
library(GGally)
library("pROC") 

#Load Data & check structure of DS
Churn <- Bank_Customer_Churn_Prediction_1_
str(Churn)
head(Churn)

#Check for missing values 
which(is.na(Churn))

#Dimensions of dataset
dim(Churn) #10,0000 observations with 12 columns

#Summarize data 
summary(Churn) 
view(Churn)

#Sum of customer churn 
sum(Churn$churn)

#put in table customer churn 
count_churn <- table(Churn$churn)
count_churn

#Create DF
DFChurn <- as.data.frame(count_churn)
DFChurn

#Change row names 
names(DFChurn) <- c("Churn","Count")
DFChurn

#If 0 then Yes to Churn 
DFChurn$Churn <- ifelse(DFChurn$Churn == 0, "Yes", "No")

#Create Pie Chart
ggplot(DFChurn, aes(x="", y=Count, fill = Churn)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) + 
  geom_text(aes(label = scales::percent(Count / sum(Count))), 
            position = position_stack(vjust = 0.5)) +
  ggtitle("Churn Distribution") +
  theme_void()

#Check distribution of credit_score (Histogram)
Churn$credit_score <- as.numeric(Churn$credit_score)
hist(Churn$credit_score)

#Check distribution of Age
Churn$age <- as.numeric(Churn$age)
hist(Churn$age)

#Churn distribution by gender 
Churn$churn <- ifelse(Churn$churn == 0, "Yes", "No")
ggplot(Churn, aes(x= churn, fill = gender))+
  geom_bar(position = "dodge") +
  labs(title = "Churn Distribution by Gender", x = "Churn")
theme_minimal()

# Churn distribution by Country  
ggplot(Churn, aes(x= churn, fill = country))+
  geom_bar(position = "dodge") +
  labs(title = "Churn Distribution by Country", x = "Churn")
theme_minimal()

#plot box plots to see distributions
Churn[, names(Churn) %in% c('age', 'balance', 'credit_score', 'estimated_salary')] %>%
  gather() %>%
  ggplot(aes(value)) +
  facet_wrap(~ key, scales = "free") +
  geom_boxplot() +
  theme(axis.text.x = element_text(size = 7, angle=90), axis.text.y = element_text(size = 7))

#Check which variables seem to be correlated to churn 
ggpairs(data=Churn, columns=2:12, title="Churn Data")
#product number & credit score seem to be correlated 
#balance & credit score seem to be correlated

#Data Transformation 

#Create factor variables for categorical variables
Churn$geodata = factor(Churn$country, labels=c("France","Germany","Spain"))
Churn$gender = factor(Churn$gender, labels=c("Male","Female"))

#Transform Data 
Churn$age = log(Churn$age)
Churn$credit_score = log(Churn$credit_score)
Churn$balance = log(Churn$balance)
Churn[Churn$balance == -Inf, 'balance'] <- 0

#Scale Data 
churn_scale_0to1 <- function(x){                           
  (x - min(x)) / (max(x) - min(x))
}
Churn$age = churn_scale_0to1(Churn$age)
Churn$credit_ccore = churn_scale_0to1(Churn$credit_score)
Churn$balance = churn_scale_0to1(Churn$balance)
Churn$estimated_salary = churn_scale_0to1(Churn$estimated_salary)

#Check data
head(Churn, 5)

#Build ML Model : Classification
trainIndex <- createDataPartition(Churn$churn, p = 0.8, list = FALSE, times = 1)
training_data <- Churn[ trainIndex,]
testing_data  <- Churn[-trainIndex,]

#Check if data was split 
prop.table(table(training_data$churn))
prop.table(table(testing_data$churn))

#Lets see which features are important to predicting customer retention - logistic regression
LogModel <- glm(churn ~., data = training_data, family = "binomial")
summary(LogModel)

#we can drop variables with (p values > 0.05)

LogModel <- glm(formula = churn ~ credit_score + country + gender + age + balance + products_number + active_member, family = "binomial", data = training_data)
summary(LogModel)

#Check VIF Scores to see multicollinearity 
vif(LogModel)


#Check model accuracy on testing data
prediction <- predict(LogModel,testing_data,type="response")
cutoff <- ifelse(prediction>=0.50, 1,0)
cm <- confusionMatrix(as.factor(testing_data$churn),as.factor(cutoff),positive ='1')
cm



#SVM Model 
training_data$churn <- as.factor(training_data$churn)

svm.model <- train(
  churn ~ ., 
  data = training_data,
  method = "svmRadial",
  trControl = trainControl(method = "none"),
  preProcess = c("center", "scale")
)
svm.model

