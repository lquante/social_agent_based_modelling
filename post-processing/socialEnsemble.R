library(ggplot2)
library(dplyr)

#load data

social_ensemble <- read.csv("/home/quante/git/social_agent_based_modelling/data/social_ensemble_2021-11-19T16:40:10.377.csv")

affinity = social_ensemble %>% group_by(tauSocial,step) %>% filter(switchingBoundary==0.5) %>% summarise(mean_affinity=mean(affinity))

ggplot(data = affinity,aes(x = step, y = mean_affinity,color=tauSocial))+geom_point()+theme_light()+labs(x="time")+scale_colour_gradientn(colours=rainbow(8))

# look at infection dynamcics

SIR_status = social_ensemble%>% filter(switchingBoundary==0.5)  %>% filter(tauSocial==0.5) %>% count(SIR_status,step)
