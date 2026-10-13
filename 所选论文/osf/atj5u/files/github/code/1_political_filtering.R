#Politically Relevant Sites 

source("code/tracking_packages.R")
deliberation_data <- readRDS(file="data/temp/data_deliberation.Rda")

# Dictionaries are in dictionaries_deliberation.R
dictionaries <- read_excel("data/temp/dictionaries.xlsx") # information and participation
forums_df <- read_excel("data/temp/forums.xlsx")          # communication
pol_keys <- read_excel("data/temp/keywords_politics_clean_f.xlsx")  # topics

topics <- pol_keys$pol_key
news <- dictionaries$news
forums <- forums_df$forum
participation <- na.omit(dictionaries$participation)

rel_category <- c("blog","forum","gaming","hobby","information","messanger","news",
                  "participation","radio","search","social_media","tv")

# irrelevant categories: astrology, banking, cashback, cooking, streaming, dating, networking, file-hosting, function, gambling,
# mail, micro_job, porn, shopping, sport, survey, tracking, transport, travel, uni, work

# lists for information and communication labelling based on top1000 categories
info_cats <- c("information","news","radio","search","tv")
comms_cats <- c("forum","messanger","social_media")

exceptions <- c("bundesliga","competition","auswahl","steuerberat",
                "reitbeteiligung","gravitationsgesetz","robotergesetz",
                "zickenkrieg","ausbildung","bearbeiten","schulze","kitarou")


# big run (over night)
deliberation_data <- readRDS(file="data/temp/data_deliberation.Rda")

#### step 1: automated filtering + labeling  ### 

filtered_big_relevant_df <- deliberation_data%>%
  #test <- deliberation_sample%>%  
  # filter out clearly  irrelevant categories
  filter(categories %in% rel_category)%>%  
  
  # filter down to politically relevant topics
  filter(str_detect(url, regex(paste(topics, collapse = "|"),ignore_case = T)))%>%  
  
  # add second layer of filtering - exclusions (to keep e.g. "wahl","bundes", and "petition")
  filter(!str_detect(url, regex(paste(exceptions, collapse = "|"),ignore_case = T)))%>%
  
  # pre-label functions (info, communication, participation) based on dictionaries and top1000 categories
  mutate(information = ifelse(str_detect(url,paste(news, collapse = "|")) | 
                                categories %in% info_cats ,1,0),  
         communication = ifelse(str_detect(url,paste(forums, collapse = "|")) | 
                                  categories %in% comms_cats ,1,0),
         participation = ifelse(str_detect(url,paste(participation, collapse = "|")) | 
                                  categories == "participation",1,0))


# saveRDS(filtered_big_relevant_df, file="data/temp/filtered_big_relevant_df.Rda")


#### step 2: prepare data to look at (domain) data manually 

filtered_big_relevant_df <-  readRDS("data/temp/filtered_big_relevant_df.Rda")

data_code_final <- filtered_big_relevant_df%>%
  group_by(domain)%>%
  mutate(clicks = n())%>%
  slice(1)%>%
  dplyr::select(index,url,domain,categories,information,communication,participation,clicks)%>%
  arrange(desc(clicks))

# write_xlsx(data_code_final,"data/temp/data_code_final.xlsx")

