# Deliberative Criterion Construction & LCA Data preparation

source("code/tracking_packages.R")

# politically relevant subset of data
filtered_big_relevant_df <- readRDS("data/temp/filtered_big_relevant_df.Rda")

# file with hand coded categories (information, communication, participation)
data_urls_clean <- read_excel("data/final/data_code_final_4_V3.xlsx") 

# merge coded domains with relevant data 
filtered_big_relevant_df$domain <- as.character(filtered_big_relevant_df$domain)
data_urls_clean$domain <- as.character(data_urls_clean$domain)
relevant_data <- left_join(x = filtered_big_relevant_df, y = data_urls_clean, by = "domain") 

# drop manually coded irrelevant domains
final_relevant_data <- relevant_data%>%
  filter(is.na(drop))

#saveRDS(final_relevant_data, file = "data/temp/relevant_data_P1a_V3.Rda")

################# ISOLATION ##################
nodes <- final_relevant_data%>%
  dplyr::select(domain)%>%
  unique()

from <- final_relevant_data%>%
  group_by(caseid)%>%
  arrange(used_at)%>%
  ungroup()%>%
  dplyr::select(domain)

# duplicating domain sequence and shifting "to" by one entry:
# insert emptyrow at beginning of "to-column"
emptyrow <- from[1,]
emptyrow$domain <- NA
to <- rbind(emptyrow,from)
colnames(to) <- c("id_to","topic_to","to")
# instert emptyrow at end of "from column"
from <- rbind(from,emptyrow)
colnames(from) <- c("id_from","topic_from","from")

edges <- cbind(from,to)

edges <- edges%>%
  na.omit()

g <- graph_from_data_frame(edges, directed=TRUE, vertices=nodes)
g_df <- as_data_frame(g, what = "both")

print(g, e=TRUE, v=TRUE)

# save(g, g_df, file = "data/temp/flow_network_df_measurement_V3.Rdata")

# remove selfloops for isolation measure
g_s <- simplify(g)
degree_data <- data.frame(degree(g_s))
degree_data$in_degree <- degree(g_s, mode = "in")
degree_data$out_degree <- degree(g_s, mode = "out")
degree_data$tot_degree <- degree(g_s, mode = "total")

degree_data_final <- degree_data%>%
  dplyr::rename(degree = degree.g_s.)%>%
  dplyr::select(degree, in_degree, out_degree)%>%
  arrange(desc(degree))%>%
  tibble::rownames_to_column("domain")

# plot isolation measure
V(g_s)$degree <- degree(g_s)

p <- ggraph(g_s,layout = "stress")+
  geom_edge_link0(edge_colour = "gray66", alpha = 0.1, arrow = arrow(angle = 10, length = unit(0.15, "inches"),
                                                                     ends = "last", type = "closed"))+
  geom_node_point(shape=21, aes(fill=degree, size = degree, alpha = 0.5), col = "white")+
  geom_node_text(aes(label = name),size = 5,family="sans")+
  scale_size(range = c(2,15)) +
  scale_alpha(range = c(0.1,1))+
  scale_fill_viridis_c(direction = -1, na.value="white", name = "Degree")+
  theme_graph()+
  theme(legend.position = c(0.95, 0.95))+
  guides(size=FALSE,alpha=FALSE)

p
#ggsave(p, file = "output/flows_measurement_V3.png", width = 7, height = 7,limitsize = FALSE, units = "cm", dpi = 300, scale = 5)

# merge isolation measure into relevant (click) data
degree_data_final$domain <- as.character(degree_data_final$domain)
final_relevant_data$domain <- as.character(final_relevant_data$domain)
final_relevant_data_rich <- left_join(x = final_relevant_data, y = degree_data_final, by = "domain") 

################# INCLUSITIVY ################
# diversity index: https://courses.lumenlearning.com/suny-natural-resources-biometrics/
# chapter/chapter-10-quantitative-measures-of-diversity-site-similarity-and-habitat-suitability/
# combination of richness (number of categories) and evenness (similar frequency)
# Shannon–Weaver
# r implementation: https://www.rdocumentation.org/packages/vegan/versions/2.4-2/topics/diversity

final_relevant_data_rich$agegroup <- cut(final_relevant_data_rich$age, breaks = c(10,20, 30, 40, 50, 60, 90), right = T, labels = F)
domain_inclusivity <- final_relevant_data_rich%>%
  dplyr::select(caseid,domain,age,agegroup,educ,gender)%>%
  na.omit()%>%
  group_by(domain)%>%
  summarise(gender_balance = diversity(gender, index = "shannon"),
            age_diversity = diversity(agegroup, index = "shannon"),
            educ_diversity = diversity(educ, index = "shannon"))

################# HETEROGENEITY ################

domain_homogeneity <- final_relevant_data_rich%>%
  dplyr::select(caseid,domain,leftright,firstvote,secondvote)%>%
  na.omit()%>%
  group_by(domain)%>%
  summarise(pol_orient_diversity = diversity(leftright, index = "shannon"),
            firstvote_diversity = diversity(firstvote, index = "shannon"),
            secondvote_diversity = diversity(secondvote, index = "shannon"))

# merge inclusivity and homogeneity into relevant dataframe
final_relevant_data_rich$domain <- as.character(final_relevant_data_rich$domain)
domain_inclusivity$domain <- as.character(domain_inclusivity$domain)
domain_homogeneity$domain <- as.character(domain_homogeneity$domain)
final_relevant_data_rich <- left_join(x = final_relevant_data_rich, y = domain_inclusivity, by = "domain")
final_relevant_data_rich <- left_join(x = final_relevant_data_rich, y = domain_homogeneity, by = "domain")

# drop irrelevant stuff
data_measurement <- final_relevant_data_rich%>%
  dplyr::select(-url.y,-categories.y,-information.y,-communication.y,-participation.y,
                -index.y,-...20,-category,-explanation)%>%
  rename_with(~str_remove(., '.x'))

colSums(is.na(data_measurement))

# saveRDS(data_measurement, file = "data/temp/data_measurement_P1a_V3.Rda")

#### LCA Data ##########

data_measurement <- readRDS("data/temp/data_measurement_P1a_V3.Rda")

# to use latent class  procedures, we need to dichotomize the isolation/diversity measures
data_LCA <- data_measurement%>%
  group_by(domain)%>%
  slice(1)%>%
  ungroup()


data_del_pot <- data_LCA%>%
  mutate(isolation_deg = ifelse(degree > median(degree),1,0),
         isolation_in = ifelse(in_degree > median(in_degree),1,0),
         isolation_out = ifelse(out_degree > median(out_degree),1,0),
         incl_gender = ifelse(gender_balance > median(gender_balance),1,0),
         incl_age = ifelse(age_diversity > median(age_diversity),1,0),
         incl_educ = ifelse(educ_diversity > median(educ_diversity),1,0),
         hom_pol_or = ifelse(pol_orient_diversity > median(pol_orient_diversity),1,0),
         hom_vote1 = ifelse(firstvote_diversity > median(firstvote_diversity),1,0),
         hom_vote2 = ifelse(secondvote_diversity > median(secondvote_diversity),1,0)
  )

data_LCA <- data_LCA%>%
  mutate(isolation_deg = ifelse(degree > median(degree),1,0),
         isolation_in = ifelse(in_degree > median(in_degree),1,0),
         isolation_out = ifelse(out_degree > median(out_degree),1,0),
         incl_gender = ifelse(gender_balance > median(gender_balance),1,0),
         incl_age = ifelse(age_diversity > median(age_diversity),1,0),
         incl_educ = ifelse(educ_diversity > median(educ_diversity),1,0),
         hom_pol_or = ifelse(pol_orient_diversity > median(pol_orient_diversity),1,0),
         hom_vote1 = ifelse(firstvote_diversity > median(firstvote_diversity),1,0),
         hom_vote2 = ifelse(secondvote_diversity > median(secondvote_diversity),1,0)
  )%>%
  dplyr::select(domain,clicks,
                info_pol,info_loc,info_qual,
                com_pr,com_rec,com_mod,
                par_par,par_actor,par_orga,
                isolation_in,isolation_out,
                incl_gender,incl_age,incl_educ,
                hom_pol_or,hom_vote1,hom_vote2)

#write_xlsx(data_del_pot, "data/temp/data_del_pot_P1a_V3.xlsx") 
#write_xlsx(data_LCA, "data/temp/data_LCA_P1a_V3.xlsx")  
