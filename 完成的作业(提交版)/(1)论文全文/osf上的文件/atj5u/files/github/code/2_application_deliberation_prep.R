#### Data Preparation - Application P1a ############

source("code/tracking_packages.R")

data_LCA_results <- read_excel("data/final/data_LCA_c_V3.xlsx")

# combine coded data with original data
deliberation_data <- readRDS(file="data/temp/data_deliberation.Rda")

# use politically relevant data for intermediate merging step
pol_rel_data <- readRDS(file="data/temp/filtered_big_relevant_df.Rda")
pol_rel_data <- pol_rel_data%>%
  dplyr::select(domain,index)

# additional pre-processing step to make left_join work properly
pol_rel_data$domain <- as.character(pol_rel_data$domain)
data_LCA_results$domain <- as.character(data_LCA_results$domain)

pol_rel_data <- left_join(pol_rel_data, data_LCA_results, by = "domain")

pol_rel_data$index <- as.numeric(pol_rel_data$index)
deliberation_data$index <- as.numeric(deliberation_data$index)

FINAL_data  <- left_join(deliberation_data, pol_rel_data, by = "index") 

# test
FINAL_data%>%
  filter(!is.na(info_pol))%>%
  glimpse()
# correct reduced to 493,714 from 516,158 political clicks
test_sample <- FINAL_data%>%
  group_by(caseid)%>%
  slice(1)
# 1282 cases - correct!
rm(deliberation_data)

# saveRDS(FINAL_data, file="data/final/FINAL_data_P1a_total.Rda")


################ Calculating per person outcome variables #################
FINAL_data <- readRDS("data/final/FINAL_data_P1a_total.Rda")

# sample sizes (clicks / domain)
FINAL_data%>%group_by(domain.x)%>%glimpse() #56,102,429 / 198,084
FINAL_data%>%filter(!is.na(info_party))%>%group_by(domain.x)%>%glimpse() #493,714 / 69
FINAL_data%>%filter(class==1)%>%group_by(domain.x)%>%glimpse() #9,963 / 22
FINAL_data%>%filter(class==2)%>%group_by(domain.x)%>%glimpse() #473,807 / 34
FINAL_data%>%filter(class==3)%>%group_by(domain.x)%>%glimpse() #9,282 / 12 

# Freq - how frequented is this domain?
# Duration - domain level duration
# duration - click duration
# online_duration - person level duration

# get person level engagement metrics
FINAL_pers_data <- FINAL_data%>%
  mutate(pol_rel_site = ifelse(!is.na(info_pol),1,0))%>% # what are political sites?
  group_by(caseid)%>%
  mutate(online_duration = sum(duration, na.rm=TRUE), # overall time online
         online_clicks = n())
# test - still 1282 cases 

### get engagement information (filter, then count clicks and duration per person)

# all political engagement
FINAL_pers_data_a <- FINAL_pers_data%>%
  filter(pol_rel_site == 1)%>%
  group_by(caseid)%>%
  mutate(pol_duration = sum(duration),
         pol_clicks = n())%>%
  dplyr::select(index,caseid,pol_duration,pol_clicks)

# C1 engagement
FINAL_pers_data_b <- FINAL_pers_data%>%
  filter(class == 1)%>%
  group_by(caseid)%>%
  mutate(c1_duration = sum(duration),
         c1_clicks = n())%>%
  dplyr::select(index,caseid,c1_duration,c1_clicks)

# C2 engagement
FINAL_pers_data_c <- FINAL_pers_data%>%
  filter(class == 2)%>%
  group_by(caseid)%>%
  mutate(c2_duration = sum(duration),
         c2_clicks = n())%>%
  dplyr::select(index,caseid,c2_duration,c2_clicks)

# C3 engagement
FINAL_pers_data_d <- FINAL_pers_data%>%
  filter(class == 3)%>%
  group_by(caseid)%>%
  mutate(c3_duration = sum(duration),
         c3_clicks = n())%>%
  dplyr::select(index,caseid,c3_duration,c3_clicks)

# weird workaround 
FINAL_pers_data$index <- as.numeric(FINAL_pers_data$index)
FINAL_pers_data_a$index <- as.numeric(FINAL_pers_data_a$index)
FINAL_pers_data_b$index <- as.numeric(FINAL_pers_data_b$index)
FINAL_pers_data_c$index <- as.numeric(FINAL_pers_data_c$index)
FINAL_pers_data_d$index <- as.numeric(FINAL_pers_data_d$index)

# joining new information (per person clicks and duration on respective pol sites) together
FINAL_pers_data_full <- left_join(FINAL_pers_data, FINAL_pers_data_a, by = "index")%>%
  left_join(., FINAL_pers_data_b, by = "index")%>%
  left_join(., FINAL_pers_data_c, by = "index")%>%
  left_join(., FINAL_pers_data_d, by = "index")


#test
pers_sample <- FINAL_pers_data_full%>%
  group_by(caseid.x)%>%
  slice(1)


## user level data
user_data_deliberation <- FINAL_pers_data_full%>%
  group_by(caseid.x)%>%
  mutate(online_duration = sum(duration, na.rm=TRUE), # do this again because it did not work before
         #get the information compressed into one row per individual
         pol_duration = mean(pol_duration, na.rm = TRUE), 
         pol_clicks = mean(pol_clicks, na.rm = TRUE),
         c1_duration = mean(c1_duration, na.rm = TRUE),
         c1_clicks = mean(c1_clicks, na.rm = TRUE),
         c2_duration = mean(c2_duration, na.rm = TRUE),
         c2_clicks = mean(c2_clicks, na.rm = TRUE),
         c3_duration = mean(c3_duration, na.rm = TRUE),
         c3_clicks = mean(c3_clicks, na.rm = TRUE))%>%
  slice(1)%>%
  mutate_at(vars(pol_duration, pol_clicks, 
                 c1_duration, c1_clicks,
                 c2_duration, c2_clicks, 
                 c3_duration, c3_clicks), 
            ~replace_na(.,0))%>% # no engagement means 0 clicks and 0 seconds
  dplyr::select(-domain.x,-host,-subdomain,-suffix,-used_at,-duration,
                -Freq,-categories,-na_count,-communication,-participation,
                -information,-caseid.y,-caseid.x.x, -caseid.y.y,-caseid)#keep caseid.x (original one!)

# saveRDS(FINAL_pers_data_full, file="data/temp/FINAL_pers_data_full_P1a.Rda")
# write_xlsx(user_data_deliberation,"data/final/user_data_deliberation_P1a.xlsx")

rm(FINAL_pers_data)
rm(FINAL_pers_data_a)
rm(FINAL_pers_data_b)
rm(FINAL_pers_data_c)
rm(FINAL_pers_data_d)
rm(FINAL_pers_data_full)


################# NEWS vs. SOCIAL MEDIA #####################################

##### OTHER 2 CATEGORIES (NEWS, SOCIAL MEDIA)

# get person level engagement metrics
FINAL_pers_data_special <- FINAL_data%>%
  group_by(caseid)%>%
  mutate(online_duration = sum(duration, na.rm=TRUE), # overall time online
         online_clicks = n())

### get engagement information (filter, then count clicks and duration per person)

# Social media
FINAL_pers_data_e <- FINAL_pers_data_special%>%
  filter(categories == "social_media" & !is.na(info_pol))%>% # also only within political clicks!
  group_by(caseid)%>%
  mutate(sm_duration = sum(duration),
         sm_clicks = n())%>%
  dplyr::select(index,caseid,sm_duration,sm_clicks)


# News
FINAL_pers_data_f <- FINAL_pers_data_special%>%
  filter(categories == "news" & !is.na(info_pol))%>% 
  group_by(caseid)%>%
  mutate(news_duration = sum(duration),
         news_clicks = n())%>%
  dplyr::select(index,caseid,news_duration,news_clicks)


# weird fuckn workaround to not make left_join do shit.....
FINAL_pers_data_special$index <- as.numeric(FINAL_pers_data_special$index)
FINAL_pers_data_e$index <- as.numeric(FINAL_pers_data_e$index)
FINAL_pers_data_f$index <- as.numeric(FINAL_pers_data_f$index)

# joining new information (per person clicks and duration on respective pol sites) together
FINAL_pers_data_full_special <- left_join(FINAL_pers_data_special, FINAL_pers_data_e, by = "index")%>%
  left_join(., FINAL_pers_data_f, by = "index")

names(FINAL_pers_data_full_special)

## user level data
user_data_deliberation_special <- FINAL_pers_data_full_special%>%
  group_by(caseid.x)%>%
  mutate(online_duration = sum(duration, na.rm=TRUE), # do this again because it did not work before
         #get the information compressed into one row per individual
         sm_duration = mean(sm_duration, na.rm = TRUE), 
         sm_clicks = mean(sm_clicks, na.rm = TRUE),
         news_duration = mean(news_duration, na.rm = TRUE),
         news_clicks = mean(news_clicks, na.rm = TRUE))%>%
  slice(1)%>%
  mutate_at(vars(sm_duration, sm_clicks, 
                 news_duration, news_clicks), 
            ~replace_na(.,0))%>% # no engagement means 0 clicks and 0 seconds
  dplyr::select(-host,-subdomain,-suffix,-used_at,-duration,
                -Freq,-categories,-na_count,-communication,-participation,
                -information,-caseid.y)#keep caseid.x (original one!)

# saveRDS(user_data_deliberation_special, file="data/temp/user_data_deliberation_special_P1.Rda")

rm(FINAL_pers_data_special)
rm(FINAL_pers_data_e)
rm(FINAL_pers_data_f)
rm(FINAL_pers_data_full_special)
rm(FINAL_data)

