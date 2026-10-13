##################### P1a Application ##################################

source("code/tracking_packages.R")

user_data_deliberation <- read_excel("data/final/user_data_deliberation_P1a.xlsx")

##### some summary stats (clicks & duration) density plots ####

# duration/click ratio
user_data_deliberation%>%
  summarize(
            c1_ratio = mean(c1_duration, na.rm=T)/mean(c1_clicks, na.rm=T),
            c2_ratio = mean(c2_duration, na.rm=T)/mean(c2_clicks, na.rm=T),
            c3_ratio = mean(c3_duration, na.rm=T)/mean(c3_clicks, na.rm=T)
            )


# Click density
all_clicks <- data.frame(Online=user_data_deliberation$online_clicks,
                         Class1=user_data_deliberation$c1_clicks,
                         Class2=user_data_deliberation$c2_clicks,
                         Class3=user_data_deliberation$c3_clicks)
all_clicks_rs <- melt(all_clicks)

fancy_scientific <- function(l) {
  # turn in to character string in scientific notation
  l <- format(l, scientific = TRUE)
  # quote the part before the exponent to keep all the digits
  l <- gsub("^(.*)e", "'\\1'e", l)
  # turn the 'e+' into plotmath format
  l <- gsub("e", "%*%10^", l)
  # return this as an expression
  parse(text=l)
}

dp1 <- ggplot(all_clicks_rs,aes(x=value, fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.94, 0.85))+
  xlab("Clicks (log)")+
  ggtitle("Cumulative Political Engagement (Clicks)")+
  scale_x_continuous(trans='log', breaks=c(1,10, 100,1000,10000,100000),labels=fancy_scientific)+
  scale_fill_jcolors(palette = "pal8", breaks=c("Class2", "Class1", "Class3", "Online"),
                     labels=c("Class 1", "Class 2", "Class 3", "Online"))
dp1

ggsave("output/density_clicks_classes.pdf", width = 6, height = 5, dpi = 300,  dp1)

# Duration density  
all_duration <- data.frame(Online=user_data_deliberation$online_duration/3600,
                         Class1=user_data_deliberation$c1_duration/3600,
                         Class2=user_data_deliberation$c2_duration/3600,
                         Class3=user_data_deliberation$c3_duration/3600)
all_duration_rs <- melt(all_duration)

dp2 <- ggplot(all_duration_rs,aes(x=value, fill=variable),) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.15, 0.85))+
  xlab("Duration in Hours (log)")+
  ggtitle("Cumulative Political Engagement (Duration)")+
  scale_x_continuous(trans='log', labels= scales::comma)+
  scale_fill_jcolors(palette = "pal8",breaks=c("Class2", "Class1", "Class3", "Online"),
                     labels=c("Class 1", "Class 2", "Class 3", "Online"))
dp2

ggsave("output/density_duration_classes.pdf", width = 6, height = 5, dpi = 300,  dp2)


# Corrected for baseline engagement (duration)
all_duration_blc <- data.frame(Class1=user_data_deliberation$c1_duration/user_data_deliberation$online_duration,
                           Class2=user_data_deliberation$c2_duration/user_data_deliberation$online_duration,
                           Class3=user_data_deliberation$c3_duration/user_data_deliberation$online_duration)
all_duration_rs_blc <- melt(all_duration_blc)

dp3 <- ggplot(all_duration_rs_blc,aes(x=value, fill=variable),) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.15, 0.87))+
  xlab("Duration (log), corrected for baseline online engagement")+
  ggtitle("Cumulative Political Engagement (Duration)")+
  scale_x_continuous(trans='log', labels= scales::comma)+
  scale_fill_jcolors(palette = "pal8",breaks=c("Class2", "Class1", "Class3"),
                     labels=c("Class 1", "Class 2", "Class 3"))
dp3

ggsave("output/density_clicks_classes_blc.pdf", width = 6, height = 5, dpi = 300,  dp3)


# Corrected for baseline engagement (clicks)
all_clicks_blc <- data.frame(Class1=user_data_deliberation$c1_clicks/user_data_deliberation$online_clicks,
                               Class2=user_data_deliberation$c2_clicks/user_data_deliberation$online_clicks,
                               Class3=user_data_deliberation$c3_clicks/user_data_deliberation$online_clicks)
all_clicks_rs_blc <- melt(all_clicks_blc)

dp4 <- ggplot(all_clicks_rs_blc,aes(x=value, fill=variable),) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.15, 0.87))+
  xlab("Clicks (log), corrected for baseline online engagement")+
  ggtitle("Cumulative Political Engagement (Clicks)")+
  scale_x_continuous(trans='log', labels= scales::comma)+
  scale_fill_jcolors(palette = "pal8",breaks=c("Class2", "Class1", "Class3"),
                     labels=c("Class 1", "Class 2", "Class 3"))
dp4

ggsave("output/density_duration_classes_blc.pdf", width = 6, height = 5, dpi = 300,  dp4)

#######################################################################################

#### run analyses on two categories websites ####
user_data_deliberations <- readRDS("data/temp/user_data_deliberation_special_P1.Rda")

##### some summary stats (clicks) density plots ####

# Click density
all_clicks <- data.frame(Online=user_data_deliberations$online_clicks,
                         Social_media=user_data_deliberations$sm_clicks,
                         News=user_data_deliberations$news_clicks)
all_clicks_rs <- melt(all_clicks)

fancy_scientific <- function(l) {
  # turn in to character string in scientific notation
  l <- format(l, scientific = TRUE)
  # quote the part before the exponent to keep all the digits
  l <- gsub("^(.*)e", "'\\1'e", l)
  # turn the 'e+' into plotmath format
  l <- gsub("e", "%*%10^", l)
  # return this as an expression
  parse(text=l)
}

jcolors("pal5")

dp5 <- ggplot(all_clicks_rs,aes(x=value, fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.91, 0.9))+
  xlab("Clicks (log)")+
  ggtitle("Cumulative Site Engagement (Clicks)")+
  scale_x_continuous(trans='log', breaks=c(1,10, 100,1000,10000,100000),labels=fancy_scientific)+
  scale_fill_jcolors(palette = "pal8")
dp5

ggsave("output/density_clicks_infocom.pdf", width = 6, height = 5, dpi = 300,  dp5)


# Corrected for baseline engagement (clicks)
all_clicks_blc <- data.frame(social_media=user_data_deliberations$sm_clicks/user_data_deliberations$online_clicks,
                             news=user_data_deliberations$news_clicks/user_data_deliberations$online_clicks)
all_clicks_rs_blc <- melt(all_clicks_blc)


dp6 <- ggplot(all_clicks_rs_blc,aes(x=value,fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.91, 0.9))+
  xlab("Clicks (log), corrected for baseline online engagement")+
  ggtitle("Cumulative Site Engagement (Clicks)")+
  scale_x_continuous(trans='log', labels= scales::comma)+
  scale_fill_jcolors(palette = "pal8", breaks = c("social_media", "news"), 
                     labels = c("social media", "news") )
dp6

ggsave("output/density_clicks_infocom_blc.pdf", width = 6, height = 5, dpi = 300,  dp6)



# Duration density
all_duration <- data.frame(online=user_data_deliberations$online_duration,
                         social_media=user_data_deliberations$sm_duration,
                         news=user_data_deliberations$news_duration)
all_duration_rs <- melt(all_duration)


dp7 <- ggplot(all_duration_rs,aes(x=value, fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.12, 0.8))+
  xlab("Duration in h (log)")+
  ggtitle("Cumulative Site Engagement (Duration)")+
  scale_x_continuous(trans='log', labels=scales::comma)+
  scale_fill_jcolors(palette = "pal8")
dp7

ggsave("output/density_duration_infocom.pdf", width = 6, height = 5, dpi = 300,  dp7)

# Corrected for baseline engagement (clicks)
all_duration_blc <- data.frame(social_media=user_data_deliberations$sm_duration/user_data_deliberations$online_duration,
                             news=user_data_deliberations$news_duration/user_data_deliberations$online_duration)
all_duration_rs_blc <- melt(all_duration_blc)


dp8 <- ggplot(all_duration_rs_blc,aes(x=value,fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.91, 0.9))+
  xlab("Duration (log), corrected for baseline online engagement")+
  ggtitle("Cumulative Site Engagement (Duration)")+
  scale_x_continuous(trans='log', labels= scales::comma)+
  scale_fill_jcolors(palette = "pal8", breaks = c("social_media", "news"), 
                     labels = c("social media", "news") )
dp8

ggsave("output/density_duration_infocom_blc.pdf", width = 6, height = 5, dpi = 300,  dp8)

######## by user subgroup ##########

user_data_deliberation$Gender <- factor(user_data_deliberation$gender,
                                        levels = c("1","2"),
                                        labels = c("male", "female"))

user_data_deliberation$age_groups <- cut(user_data_deliberation$age, 
                                         breaks = c(17,30,60,90),right = T, left = T, 
                                         labels = c("<30","30-60", ">60"))

# Age & Gender
all_clicks <- data.frame(age = user_data_deliberation$age_groups,
                         gender = user_data_deliberation$Gender,
                         Online=user_data_deliberation$online_clicks,
                         Class1=user_data_deliberation$c1_clicks,
                         Class2=user_data_deliberation$c2_clicks,
                         Class3=user_data_deliberation$c3_clicks)

all_clicks_rs <- pivot_longer(all_clicks, cols = c(Online,Class1,Class2,Class3),
                              names_to = "clicks")%>%
  na.omit()

smp1 <- ggplot(all_clicks_rs,aes(x=value, fill=clicks)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  #theme(legend.position = c(0.94, 0.85))+
  xlab("Clicks (log)")+
  ggtitle("Cumulative Political Engagement (Clicks)")+
  scale_x_continuous(trans='log', breaks=c(1,10, 100,1000,10000,100000),labels=fancy_scientific)+
  scale_fill_jcolors(palette = "pal8", breaks=c("Class2", "Class1", "Class3", "Online"),
                     labels=c("Class 1", "Class 2", "Class 3", "Online"))+
  facet_grid(gender ~ age)
smp1

ggsave("output/density_clicks_classes_smp.pdf", width = 12, height = 5, dpi = 300,  smp1)

# Education 

user_data_deliberation <- user_data_deliberation %>%
                                      mutate(education = na_if(educ, "6"),# NA
                                             education = na_if(educ, "1"), # still in hs
                                             education = ifelse(educ == 5, 2 ,educ)) # pool no degree + Hauptschule
user_data_deliberation$education <- factor(user_data_deliberation$education,
                                           levels = c("2","3","4"), labels = c("No degree / Hauptschule", 
                                                                                   "Realschule", "Abitur"))

# Age & Gender
all_clicks <- data.frame(education = user_data_deliberation$education,
                         Online=user_data_deliberation$online_clicks,
                         Class1=user_data_deliberation$c1_clicks,
                         Class2=user_data_deliberation$c2_clicks,
                         Class3=user_data_deliberation$c3_clicks)

all_clicks_rs <- pivot_longer(all_clicks, cols = c(Online,Class1,Class2,Class3),
                              names_to = "clicks")%>%
  na.omit()

smp2 <- ggplot(all_clicks_rs,aes(x=value, fill=clicks)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  #theme(legend.position = c(0.94, 0.85))+
  xlab("Clicks (log)")+
  ggtitle("Cumulative Political Engagement (Clicks)")+
  scale_x_continuous(trans='log', breaks=c(1,10, 100,1000,10000,100000),labels=fancy_scientific)+
  scale_fill_jcolors(palette = "pal8", breaks=c("Class2", "Class1", "Class3", "Online"),
                     labels=c("Class 1", "Class 2", "Class 3", "Online"))+
  facet_grid(. ~ education)
smp2

ggsave("output/density_clicks_classes_smp2.pdf", width = 12, height = 3, dpi = 300,  smp2)


