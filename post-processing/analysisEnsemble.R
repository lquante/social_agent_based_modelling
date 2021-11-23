library(ggplot2)
library(dplyr)

#load data

ensemble <- read.csv("/home/quante/git/social_agent_based_modelling/data/transmission_ensemble_2021-11-23T09:25:13.503.csv")

affinity = ensemble %>% group_by(transmissionUndetected,step) %>% summarise(mean_affinity=mean(affinity))

ggplot(data = affinity,aes(x = step, y = mean_affinity,color=transmissionUndetected))+geom_point()+theme_light()+labs(x="time")+scale_colour_gradientn(colours=rainbow(5))

# look at infection dynamcics

SIR_count = ensemble  %>% filter(transmissionUndetected==0.5,transmissionDetected==0.005) %>% group_by(step, SIR_status) %>%tally()

ggplot(data = SIR_count, aes(x = step, y = n, color=SIR_status))+geom_line()+theme_light()
