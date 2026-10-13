# Descriptives about Online Public Sphere

source("code/tracking_packages.R")
data_del_pot <- read_xlsx("data/temp/data_del_pot_P1a_V3.xlsx")
data_LCA <- read_xlsx("data/temp/data_LCA_P1a_V3.xlsx")

# percentage news in politically relevant websites
data_del_pot%>%
  filter(categories == "news")

# communication platforms that are social media platforms
data_del_pot%>%
  filter(com_pr > 0 & categories == "social_media")

########## Frequency of Insfrastructure Criteria #######################
dfplot <- data_del_pot %>%
  dplyr::select(info_pol,info_loc,info_qual,com_pr,com_rec,par_actor,par_orga,par_par)%>%
  pivot_longer(cols = everything())%>%
  ggplot() +
  geom_bar(aes(x = reorder(name, value), alpha = factor(value)), fill = "#194D44")+
  scale_alpha_manual(values =c(0.1,0.8),
                     labels = c("0", "1"))+
  theme_bw()+
  theme(legend.position = "none")+
  scale_x_discrete(breaks = c(
    "info_pol","info_loc","info_qual","com_pr","com_rec","par_actor",
    "par_orga","par_par"),
    labels = c("Political information",
               "Admin/local information",
               "Information curation",
               "Communicative expression",
               "Communicative reciprocity",
               "Contact to politicians",
               "Political organization",
               "Online participation"
    ))+
  ylab("Count")+
  xlab("")+
  coord_flip()+
  ggtitle("Deliberative Potential Features in Sample")
dfplot
#ggsave("output/feature_frequency.pdf", width = 7, height = 6, dpi = 300, dfplot)


################### DELIBERATIVE FEATURE DESCRIPTIVES ############

data_rankings <- data_LCA%>%
  mutate(information = (info_pol+info_loc+info_qual)/3,
         communication = (com_pr+com_rec)/2,
         participation = (par_actor+par_orga+par_par)/3,
         isolation = in_degree+out_degree, #quit manual isolation measure
         inclusivity = gender_balance+age_diversity+educ_diversity,
         heterogeneity = pol_orient_diversity+firstvote_diversity)


## create density plots

# Hand coded criteria
all_clicks <- data.frame(Information=data_rankings$information,
                         Communication=data_rankings$communication,
                         Participation=data_rankings$participation)

all_clicks_rs <- melt(all_clicks)

handfp <- ggplot(all_clicks_rs,aes(x=value, fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.8, 0.8))+
  xlab("Feature Presence (Percent Possible)")+
  ggtitle("Cumulative Features of Website Infrastructures")+
  scale_fill_manual(values = c("#194D44","#C6CF6E","#5B6DC8"))
handfp

#ggsave("output/density_handfp.pdf", width = 5, height = 4, dpi = 300,  handfp)


# Demand criteria
all_clicks <- data.frame(Isolation=scale(data_rankings$isolation),
                         Inclusivity=scale(data_rankings$inclusivity),
                         Heterogeneity=scale(data_rankings$heterogeneity))

all_clicks_rs <- melt(all_clicks)

compfp <- ggplot(all_clicks_rs,aes(x=value, fill=variable)) + 
  geom_density(alpha=0.6)+
  theme_minimal()+
  theme(legend.position = c(0.15, 0.8))+
  xlab("Feature Presence (Scaled)")+
  ggtitle("Cumulative Website Demand Features")+
  scale_fill_manual(values = c("#194D44","#C6CF6E","#5B6DC8"))
compfp

#ggsave("output/density_compfp.pdf", width = 5, height = 4, dpi = 300,  compfp)

p <- grid.arrange(dfplot, handfp, compfp, nrow = 1)
#ggsave("output/feature_descriptives_combi.pdf", width = 15, height = 5, dpi = 300, p)

####################### Correlation Plot ###########################

potential_indicators <- data_LCA%>%
  dplyr::rename("Clicks" = clicks,
                "Political information" = info_pol,
                "Admin/local information" = info_loc,  
                "Information curation" = info_qual,  
                "Communicative expression" = com_pr,     
                "Communicative reciprocity" = com_rec,    
                "Participation" = par_par,   
                "Contact to politicians" = par_actor,  
                "Political organization" = par_orga,   
                "Ingoing traffic" = isolation_in,
                "Outgoing traffic" = isolation_out,
                "Gender inclusivity" = incl_gender,
                "Age inclusivity" = incl_age,  
                "Educational inclusivity" = incl_educ, 
                "Political opinion heterogeneity" = hom_pol_or, 
                "Party preference heterogeneity" = hom_vote1)%>%
  dplyr::select(-domain,-com_mod,-hom_vote2)

corr <- round(cor(potential_indicators), 1)
p.mat <- cor_pmat(potential_indicators)

corrplot(corr, addrect = 2,tl.col="black",tl.cex = 0.8,
         col=colorRampPalette(c("#943CB4","white","#194D44"))(200))
#ggsave("output/corrplot_nice.pdf", dpi = 300)
