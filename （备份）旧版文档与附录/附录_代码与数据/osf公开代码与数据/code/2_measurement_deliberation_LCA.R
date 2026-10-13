###############################################################################
###### Latent Class Analysis - Deliberative Potential of Websites  ############
###############################################################################

source("code/tracking_packages.R")

data_LCA <- read_excel("data/temp/data_LCA_P1a_V3.xlsx")

# validation: randomly remove 10, 25, 50% of sample
#data_LCA <- sample_n(data_LCA, 62) # - 10%
#data_LCA <- sample_n(data_LCA, 48) # - 30%
#data_LCA <- sample_n(data_LCA, 35) # - 50%

# for LCA we need positive integers (recode 0 to 2)
data_LCA_n <- data_LCA %>%
  mutate_if(is.integer, as.numeric) %>%
  mutate_at(vars(info_pol:hom_vote2), funs(recode(.,`0` = 1, `1` = 2)))

# define function - only use in/out degree and two homogeneity values because same
f<-with(data_LCA_n, cbind(info_pol,info_loc,info_qual,
                        com_pr,com_rec,
                        par_par,par_actor,par_orga,
                        isolation_in,isolation_out,
                        incl_gender,incl_age,incl_educ,
                        hom_pol_or,hom_vote1)~1) 


# validation run whith 3 criteria dropped:
#f<-with(data_LCA_n, cbind(info_pol,info_loc,info_qual,
#                          com_pr,com_rec,
#                          par_par,par_actor,par_orga,
#                          isolation_in,isolation_out,
#                          incl_gender,
#                          hom_pol_or)~1) 

# validation run with hand-coded only vs. automated only:
#f<-with(data_LCA_n, cbind(info_pol,info_loc,info_qual,
#                          com_pr,com_rec,
#                          par_par,par_actor,par_orga)~1) 

#f<-with(data_LCA_n, cbind(isolation_in,isolation_out,
#                          incl_gender,incl_age,incl_educ,
#                          hom_pol_or,hom_vote1)~1) 
#


# run a sequence of models with 1-10 classes and print out the model with the lowest BIC
max_II <- -100000
min_bic <- 100000

set.seed(9876)

for(i in 1:10){
  lc <- poLCA(f, data_LCA_n, nclass=i, maxiter=3000, 
              tol=1e-5, na.rm=FALSE,  
              nrep=10, verbose=TRUE, calc.se=TRUE)
  
  if(lc$bic < min_bic){
    min_bic <- lc$bic
    LCA_best_model<-lc
  }
}    	

LCA_best_model 
lc <- poLCA(f, data=data_LCA_n, nclass=1, na.rm = FALSE, nrep=30, maxiter=3000)
lc3 <-poLCA(f, data=data_LCA_n, nclass=3, na.rm = FALSE, nrep=30, maxiter=3000)
lc2 <-poLCA(f, data=data_LCA_n, nclass=2, na.rm = FALSE, nrep=30, maxiter=3000)

# generate dataframe with all models and fit-values
models <- c()
lliks <- c()
dfs <- c()
BICs <- c()
ABICs <- c()
CAICs <- c()
Gsqs <- c()

for(i in 1:10){
  
  lc<-poLCA(f, data=data_LCA_n, nclass=i, na.rm = FALSE, nrep=30, maxiter=3000)
  
  models <- c(models, paste('model',i))
  lliks <- c(lliks, lc$llik)
  dfs <- c(dfs, lc$resid.df)
  BICs <- c(BICs, lc$bic)
  ABICs <- c(ABICs, (-2*lc$llik) + ((log((lc$N + 2)/24)) * lc$npar))
  CAICs <- c(CAICs, (-2*lc$llik) + lc$npar * (1 + log(lc$N)))
  Gsqs <- c(Gsqs, lc$Gsq)
}

LCA_results <- data.frame(Model = models, Log_Likelihoods = lliks,
                      Df = dfs, BIC = BICs, aBIC = ABICs, AIC = CAICs, 
                      Likelihood_Ratios = Gsqs)



LCA_results%>%
  mutate_if(is.numeric, round)%>%
  xtable()%>%
  kable("latex")


# Elbow-Plot
LCA_results$Model <- as_factor(LCA_results$Model) 

#convert to long format
results2<-tidyr::gather(LCA_results,Criterion,Value,4:7)
results2

#plot
fit.plot<-ggplot(results2) + 
  geom_point(aes(x=Model,y=Value),size=3) +
  geom_line(aes(Model, Value, group = 1)) +
  theme_bw()+
  labs(x = "", y="", title = "") + 
  facet_grid(Criterion ~. ,scales = "free") +
  theme_bw(base_size = 16, base_family = "") +   
  theme(panel.grid.major.x = element_blank() ,
        panel.grid.major.y = element_line(colour="grey", size=0.5),
        legend.title = element_text(size = 16, face = 'bold'),
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 12),
        legend.text=  element_text(size=12),
        axis.line = element_line(colour = "black")) # Achsen etwas dicker

# save 650 x 800
fit.plot
#ggsave(fit.plot, file = "output/LCA_fit.png", width = 5, height = 4,limitsize = FALSE, units = "cm", dpi = 300, scale = 5)


#lc$predclass gives a vector of predicted class membership for each respondent.
#lc$posterior gives a matrix of probabilities for each respondent and each class.

# population shares
round(colMeans(lc$posterior)*100,2)
round(colMeans(lc3$posterior)*100,2)
round(colMeans(lc2$posterior)*100,2)

# estimated class membership
table(lc$predclass)
table(lc3$predclass)
table(lc2$predclass)

round(prop.table(table(lc$predclass)),4)*100
round(prop.table(table(lc3$predclass)),4)*100
round(prop.table(table(lc2$predclass)),4)*100

lcmodel <- reshape2::melt(lc3$probs, level=2)
lcmodel2 <- reshape2::melt(lc2$probs, level=2)


########################## MODEL WITH 3 CLASSES #####################

#make nicer labels
L2_nice <- lcmodel$L2%>%
  dplyr::recode(info_pol = "political information",
        info_loc = "admin/local information",
        info_qual = "information curation",
        com_pr = "communicative expression",
        com_rec = "communicative reciprocity",
        com_mod = "moderation",
        par_par = "participation",
        par_actor = "contact to politicians",
        par_orga = "political organization",
        isolation_in = "ingoing traffic",
        isolation_out = "outgoing traffic",
        incl_gender = "gender inclusivity",
        incl_age = "age inclusivity",
        incl_educ = "educational inclusivity",
        hom_pol_or = "political opinion heterogeneity",
        hom_vote1 = "party preference heterogeneity")

lcmodel$L2 <- L2_nice
# keep order
lcmodel$L2 <- factor(lcmodel$L2, levels=c("political information",
                                          "admin/local information",
                                          "information curation",
                                          "communicative expression",
                                           "communicative reciprocity",
                                          "moderation",
                                           "participation",
                                           "contact to politicians",
                                          "political organization",
                                           "ingoing traffic",
                                          "outgoing traffic",
                                        "gender inclusivity",
                                           "age inclusivity",
                                           "educational inclusivity",
                                          "political opinion heterogeneity",
                                            "party preference heterogeneity"))


######## Plot with colours ########
lcmodel <- lcmodel%>%
  mutate(group = case_when(L2 %in% c("political information",
                                     "admin/local information",
                                     "information curation") ~ "information",
                           L2 %in% c("communicative expression",
                                     "moderation",
                                     "communicative reciprocity") ~ "communication",
                           L2 %in% c("participation",
                                     "contact to politicians",
                                     "political organization") ~ "participation",
                           L2 %in% c("ingoing traffic",
                                     "outgoing traffic") ~ "isolation",
                           L2 %in% c("gender inclusivity",
                                     "age inclusivity",
                                     "educational inclusivity") ~ "inclusivity",
                           L2 %in% c("political opinion heterogeneity",
                                     "party preference heterogeneity") ~ "heterogeneity"))

lcmodel$L2 <- factor(lcmodel$L2, levels = c("party preference heterogeneity",
                                            "political opinion heterogeneity",
                                            "educational inclusivity",
                                            "age inclusivity",
                                            "gender inclusivity",
                                            "outgoing traffic",
                                            "ingoing traffic",
                                            "political organization",
                                            "contact to politicians",
                                            "participation",
                                            "communicative reciprocity",
                                            "communicative expression",
                                            "information curation",
                                            "admin/local information",
                                            "political information"),
                     labels = c("Party preference heterogeneity",
                                "Political opinion heterogeneity",
                                "Educational inclusivity",
                                "Age inclusivity",
                                "Gender inclusivity",
                                "Outgoing traffic",
                                "Ingoing traffic",
                                "Political organization",
                                "Contact to politicians",
                                "Participation",
                                "Communicative reciprocity",
                                "Communicative expression",
                                "Information curation",
                                "Admin/local information",
                                "Political information"))

lcmodel$class <- factor(lcmodel$Var1, levels = c("class 3: ","class 2: ","class 1: "))
levels(lcmodel$class) <- c("Class 1", "Class 2", "Class 3")
zp1f <- ggplot(lcmodel,aes(x = value, y = L2, fill = group, alpha = Var2))+ 
  geom_bar(stat = "identity", position = "stack")+ 
  facet_grid(. ~ class)+ 
  scale_alpha_manual(values =c(0.1,1),
                     labels = c("no", "yes"))+
  scale_fill_jcolors(palette = "pal8")+
  theme_bw()+ 
  labs(y = "Deliberative Potential Criteria",x="Conditional probabilities of criteria in classes", 
       fill ="Dimension",alpha = "Evaluation")+ 
  theme( axis.text.x=element_text(size = 10),
         axis.ticks.x=element_blank(), 
         axis.title.y = element_text(size = 12),
         axis.text.y = element_text(),
         panel.grid.major.y=element_blank(),
         strip.background =element_rect(fill="black"),
         strip.text = element_text(colour = 'white'))+
  guides(fill = "none", alpha = "none")

zp1f
ggsave(file = "output/bars_LCA_V3_final_colour_flipped.pdf", width = 10, height = 6, dpi = 300, zp1f)



# work around to get individual class membership
membership <- data.frame(round(lc3$posterior[0:69,],2)) # change this in validation run
data_LCA_a <- cbind(data_LCA,membership)

data_LCA_c <- data_LCA_a %>%
  mutate(class = case_when(X1 == 1 ~ "1",
                 X2 == 1 ~ "2",
                 X3 == 1 ~ "3"))

psc <- data_LCA_c%>%
  na.omit()%>%
  ggplot(., aes(x = class, color = class, y = clicks))+
  geom_point(size = 8, alpha = 0.5, 
             position = position_jitter(0.4,0.5, seed=123))+
  geom_text(aes(label=domain),size = 1.5,color = "black",
            position = position_jitter(0.4,0.5, seed=123))+
  scale_y_continuous(trans='log10')+
  scale_color_brewer("Accent", direction=-1,na.value="white")+
  theme_minimal()+
  theme(axis.title.y = element_text(size = 6),
        axis.title.x = element_text(size = 6),
        axis.text.x = element_text(size = 6),
        axis.text.y = element_text(size = 4))+
  guides(color="none")
psc

########################## MODEL WITH 2 CLASSES #####################

#make nicer labels
L2_nice <- lcmodel2$L2%>%
  dplyr::recode(info_pol = "political information",
                info_loc = "admin/local information",
                info_qual = "information curation",
                com_pr = "communicative expression",
                com_rec = "communicative reciprocity",
                com_mod = "moderation",
                par_par = "participation",
                par_actor = "contact to politicians",
                par_orga = "political organization",
                isolation_in = "ingoing traffic",
                isolation_out = "outgoing traffic",
                incl_gender = "gender inclusivity",
                incl_age = "age inclusivity",
                incl_educ = "educational inclusivity",
                hom_pol_or = "political opinion heterogeneity",
                hom_vote1 = "party preference heterogeneity")

lcmodel2$L2 <- L2_nice
lcmodel2$class <- factor(lcmodel2$Var1, levels = c("class 1: ","class 2: "))
levels(lcmodel2$class) <- c("Class 1", "Class 2")
# keep order
lcmodel2$L2 <- factor(lcmodel2$L2, levels=c("political information",
                                          "admin/local information",
                                          "information curation",
                                          "communicative expression",
                                          "communicative reciprocity",
                                          "moderation",
                                          "participation",
                                          "contact to politicians",
                                          "political organization",
                                          "ingoing traffic",
                                          "outgoing traffic",
                                          "gender inclusivity",
                                          "age inclusivity",
                                          "educational inclusivity",
                                          "political opinion heterogeneity",
                                          "party preference heterogeneity"))

######## Plot with colours ########
lcmodel2 <- lcmodel2%>%
  mutate(group = case_when(L2 %in% c("political information",
                                     "admin/local information",
                                     "information curation") ~ "information",
                           L2 %in% c("communicative expression",
                                     "moderation",
                                     "communicative reciprocity") ~ "communication",
                           L2 %in% c("participation",
                                     "contact to politicians",
                                     "political organization") ~ "participation",
                           L2 %in% c("ingoing traffic",
                                     "outgoing traffic") ~ "isolation",
                           L2 %in% c("gender inclusivity",
                                     "age inclusivity",
                                     "educational inclusivity") ~ "inclusivity",
                           L2 %in% c("political opinion heterogeneity",
                                     "party preference heterogeneity") ~ "heterogeneity"))

lcmodel2$L2 <- factor(lcmodel2$L2, levels = c("party preference heterogeneity",
                                            "political opinion heterogeneity",
                                            "educational inclusivity",
                                            "age inclusivity",
                                            "gender inclusivity",
                                            "outgoing traffic",
                                            "ingoing traffic",
                                            "political organization",
                                            "contact to politicians",
                                            "participation",
                                            "communicative reciprocity",
                                            "communicative expression",
                                            "information curation",
                                            "admin/local information",
                                            "political information"))


zp2f <- ggplot(lcmodel2,aes(x = value, y = L2, fill = group, alpha = Var2))+ 
  geom_bar(stat = "identity", position = "stack")+ 
  facet_grid(. ~ class)+ 
  scale_alpha_manual(values =c(0.1,1),
                     labels = c("no", "yes"))+
  scale_fill_jcolors(palette = "pal8")+
  theme_bw()+ 
  labs(y = "Deliberative Potential Criteria",x="Conditional probabilities of criteria in classes", 
       fill ="Dimension",alpha = "Evaluation")+ 
  theme( axis.text.x=element_text(size = 10),
         axis.ticks.x=element_blank(), 
         axis.title.y = element_text(size = 12),
         axis.text.y = element_text(),
         panel.grid.major.y=element_blank(),
         strip.background =element_rect(fill="black"),
         strip.text = element_text(colour = 'white'))+
  guides(fill = "none", alpha = "none")

zp2f
ggsave(file = "output/bars_LCA_V3_final_colour_flipped.pdf", width = 8, height = 6, dpi = 300, zp2f)

# work around to get individual class membership
membership <- data.frame(round(lc2$posterior[0:69,],2))
data_LCA_d <- cbind(data_LCA,membership)

data_LCA_x <- data_LCA_d%>%
  mutate(class = case_when(X1 == 1 ~ "1",
                           X2 == 1 ~ "2"))

psc <- data_LCA_x%>%
  na.omit()%>%
ggplot(., aes(x = class, color = class, y = clicks))+
  geom_point(size = 8, alpha = 0.5, 
             position = position_jitter(0.4,0.5, seed=123))+
  geom_text(aes(label=domain),size = 1.5,color = "black",
            position = position_jitter(0.4,0.5, seed=123))+
  scale_y_continuous(trans='log10')+
  scale_color_brewer("Accent", direction=-1,na.value="white")+
  theme_minimal()+
  theme(axis.title.y = element_text(size = 6),
        axis.title.x = element_text(size = 6),
        axis.text.x = element_text(size = 6),
        axis.text.y = element_text(size = 4))+
  guides(color="none")
psc

######### Membership Tables ############################
# 3 classes
names(data_LCA_c)

a <- data_LCA_c%>%
  dplyr::select(domain,clicks,class)%>%
  filter(class == "1")%>%
  arrange(desc(clicks))%>%
  dplyr::select(-class)%>%
  dplyr::rename(C1_domains = domain)
b <- data_LCA_c%>%
  dplyr::select(domain,clicks,class)%>%
  filter(class == "2")%>%
  arrange(desc(clicks))%>%
  dplyr::select(-class)%>%
  dplyr::rename(C2_domains = domain)
c <- data_LCA_c%>%
  dplyr::select(domain,clicks,class)%>%
  filter(class == "3")%>%
  arrange(desc(clicks))%>%
  dplyr::select(-class)%>%
  dplyr::rename(C3_domains = domain)

membership_df_3 <- cbindX(a,b,c)
membership_df_3%>%
  kbl(caption = "Class Memberships", booktabs = T, format = "latex")%>%
  kable_styling(latex_options = c("hold_position"))

  

# 2 classes
names(data_LCA_x)

a <- data_LCA_x%>%
  dplyr::select(domain,clicks,class)%>%
  filter(class == "1")%>%
  arrange(desc(clicks))%>%
  dplyr::select(-class)%>%
  dplyr::rename(C1_domains = domain)
b <- data_LCA_x%>%
  dplyr::select(domain,clicks,class)%>%
  filter(class == "2")%>%
  arrange(desc(clicks))%>%
  dplyr::select(-class)%>%
  dplyr::rename(C2_domains = domain)

membership_df_2 <- cbindX(a,b)
membership_df_2%>%
  kbl(caption = "Class Memberships", booktabs = T, format = "latex")%>%
  kable_styling(latex_options = c("hold_position"))



#################### Network Data ######################################

# plot network with classes 

load("data/temp/flow_network_df_measurement_V3.Rdata")

# remove selfloops for isolation measure
g_s <- simplify(g)
V(g_s)$degree <- degree(g_s)

# add class information to graph object
df <- igraph::as_data_frame(g_s, 'both')

df$vertices <- df$vertices %>% 
  left_join(data_LCA_c, c('name'='domain'))# decide which class model (2/3?)

g_s_n <- graph_from_data_frame(df$edges,
                                   directed = F,
                                   vertices = df$vertices)

g_s_n <- delete_vertices(g_s_n, "rosenheim24") # NA value


p2 <- ggraph(g_s_n,layout = "stress")+
  geom_edge_link0(edge_colour = "gray66", alpha = 0.1, arrow = arrow(angle = 10, length = unit(0.15, "inches"),
                                                                     ends = "last", type = "closed"))+
  geom_node_point(shape=21, aes(fill=class, size = degree, alpha = 0.5), col = "white")+
  geom_node_text(aes(label = name),size = 5,family="sans")+
  scale_size(range = c(2,15)) +
  scale_alpha(range = c(0.1,1))+
  scale_fill_brewer("Accent", direction=-1,na.value="white")+
  theme_graph()+
  theme(legend.position = c(0.95, 0.95))+
  guides(size="none",alpha="none")

p2
ggsave(p2, file = "output/flows_measurement_classes_V3_3.png", width = 7, height = 7,limitsize = FALSE, units = "cm", dpi = 300, scale = 5)

#### write data with deliberative potential information - input for paper 3  
#write_xlsx(data_LCA_c, "data/final/data_LCA_c_V3.xlsx")  
 
