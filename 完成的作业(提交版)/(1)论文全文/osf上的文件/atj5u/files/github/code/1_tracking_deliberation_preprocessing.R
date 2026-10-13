# Data Preprocessing - integrating URL + survey data

source("code/tracking_packages.R")

# load tracking-data pulse_df - careful, 1,16 GB!
load("data/raw/pulse_weburls_jul2017_dec_2017_df.RData")

# extract domains
domain_info <- suffix_extract(domain(pulse_df$url))
data <- data.frame(cbind(domain_info, pulse_df))

# manually label top 1000 domains
top_1000 <- data.frame(head(sort(table(data$domain), decreasing = T), n = 1000))

# write_xlsx(top_1000, "data/temp/top_1000.xlsx")

# label label label ...

top_1000_cat_man <- read_excel("data/final/top_1000_cat_man.xlsx")

full_data <- merge(x = data, y = top_1000_cat_man, 
                   by.x = "domain", by.y = "Var1", all.x = TRUE)

# recode some categories
full_data <- full_data%>%
  mutate(categories = recode(categories, 
         `image_hosting` = "file-hosting",
         `image-hosting` = "file-hosting",
         `form` = "forum",
         `blacklist_check` = "function",
         `design` = "hobby",
         `data` = "work",
         `games` = "gaming"))

#saveRDS(full_data, file="data/temp/full_data.Rda")

# table of top 1000 domain categories
cat_tab <- full_data %>%
  group_by(categories)%>%
  mutate(clicks = n())%>%
  arrange(desc(clicks))%>%
  select(categories, clicks)%>%
  kbl(caption = "Top 1000 domains", booktabs = T, format = "latex") %>%
  kable_styling(latex_options = c("striped", "hold_position"))
 
# Preprocessing of survey data
load("data/raw/ger_survey_2017_long.RData")

survey_data <- waves_df_long%>%
 select(personid, gender,
        age, educ, relationship,
        employment, workstatus, hhincome,
        postcode, polinterest, demsatis, leftright, likelihoodvote,
        firstvote, secondvote, votecertainty,
        internetdesktop,internetmobile,internetusage_socialmedia,internetusage_politics ,
        internetusage_information, internetusage_communitites)

names(survey_data)[names(survey_data)=="personid"] <- "caseid"

# keep only one row per case (with least NAs)
survey_data$na_count <- rowSums(is.na(survey_data))
survey_data_compact <- survey_data %>%
  group_by(caseid)%>%
  arrange(na_count)%>%
  slice(1)

# fix leading zeros issue in zip-codes of survey data
zeros <- function(x)
{
  if(is.na(x)) {
    NA
  }
  else if(nchar(x)<5){
    paste0(0,x)
  }
  else{
    x
  }
}

survey_data_compact$postcode <- sapply(survey_data_compact$postcode, zeros)

# merge survey data with url data
deliberation_data <- left_join(x = full_data, y = survey_data_compact, by = "caseid")

# create an index to facilitate later merging 
deliberation_data <- deliberation_data%>%
  dplyr::mutate(index = row_number())

#saveRDS(deliberation_data, file="data/temp/data_deliberation.Rda")

# pull get for code-test purposes
deliberation_sample <- deliberation_data%>%
  sample_n(10000)

#saveRDS(deliberation_sample, file = "data/temp/deliberation_sample.Rda")
