library(ggplot2)
library(dplyr)

#load data

social_ensemble <- read.csv("/home/quante/git/social_network_modelling/social_agent_based_modelling/data/social_ensemble_dorogotsev_2021-10-22T15:08:45.093.csv")

# get frequency per timestep

affinity = social_ensemble %>% group_by(tauSocial,step) %>% summarise(mean_affinity=mean(affinity))
# make simple plot

ggplot(data = affinity,aes(x = step, y = mean_affinity,color=tauSocial))+geom_point()+theme_light()+labs(x="time")+scale_colour_gradientn(colours=rainbow(8))
