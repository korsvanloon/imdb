# Regression Tree Example
library(rpart)
library(rpart.plot)

data = read.csv(file="../out/normalised_movies2", head=TRUE, sep="\t")

linearRegression = function() {
  formula = rating ~ editors + directors + producers + writers + actors + actresses + cinematographers + composers + costumeDesigners + productionCompanies + specialEffectsCompanies
  fit = lm(formula, data=data)
  summary(fit)
  coefficients(fit)
}

regressionTree = function() {
  formula = rating ~ genres + editors + directors + producers + writers + actors + actresses + cinematographers + composers + costumeDesigners + productionCompanies + specialEffectsCompanies
  fit = rpart(formula, data, method='anova', control=rpart.control(cp=0.0008))
  #plotcp(fit) # visualize cross-validation results 
  #printcp(fit) # display the results 
  #summary(fit) # detailed summary of splits
  prp(fit, cex=0.7)
}

coef = linearRegression()
print(coef)
print(sum(c(1.0,0.63,0.63,0.7,0.4) * coef))
#regressionTree()
# create additional plots 
#par(mfrow=c(1,1)) # two plots on one page 


