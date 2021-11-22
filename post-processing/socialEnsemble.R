library(ggplot2)
library(dplyr)

#load data

ensemble <- read.csv("/home/quante/git/social_agent_based_modelling/data/transmission_ensemble_2021-11-22T17:37:59.803.csv")

affinity = ensemble %>% group_by(transmissionUndetected,step) %>% summarise(mean_affinity=mean(affinity))

ggplot(data = affinity,aes(x = step, y = mean_affinity,color=transmissionUndetected))+geom_point()+theme_light()+labs(x="time")+scale_colour_gradientn(colours=rainbow(5))

# look at infection dynamcics

SIR_status = ensemble  %>% filter(transmissionUndetected==0.5) %>% group_by(step, SIR_status) %>%tally()

ggplot(data = SIR_status, aes(x = step, y = n)+geom_line()+theme_light()+labs(x="time"))
