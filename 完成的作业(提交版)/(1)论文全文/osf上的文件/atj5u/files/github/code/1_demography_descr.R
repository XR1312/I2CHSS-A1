# Demography & Descriptives 

source("code/tracking_packages.R")

deliberation_data <- readRDS(file="data/temp/data_deliberation.Rda")

#### SAMPLE

# N - URL clicks
nrow(deliberation_data)

# N users 
length(table(deliberation_data$caseid))

# date range
range(deliberation_data$used_at, na.rm=TRUE)

# sample
sample <- deliberation_data%>%
  group_by(caseid)%>%
  slice(1)

# gender
table(sample$gender)

# age
ggplot(sample, aes(x=age))+
  geom_histogram(fill = "grey", colour = "darkgrey")+
  theme_minimal()+
  xlab("Age")+
  ylab("Frequency")

# education 
table(sample$educ)%>%
  xtable()

# Political Orientation
ggplot(sample)+
  geom_histogram(aes(x = leftright, fill = ..x..), binwidth = 1)+
  theme_minimal()+
  scale_fill_gradient2(low='darkred', mid='lightgrey', high='darkblue', midpoint=6)+
  xlab("Political Orientation")+
  ylab("Frequency")+
  theme(legend.position = "none")+
  xlim("very left", "", "left wing", "", "rather left", "", "rather right", "",
       "right wing", "", "very right")

# Region

# load zip-code shape file
ger_plz <- st_read("data/raw/plz-gebiete.shp/plz-gebiete.shp")

# clicks per postcode
activity <- data.frame(table(deliberation_data$postcode))

# merge activity with shape
plz_data <- merge(x=ger_plz , y=activity, by.x = "plz", by.y = "Var1", all.x = TRUE)

quartz()
ggplot() +
  geom_sf(data = plz_data, size = 0.01, aes(fill = Freq), color="lightgrey") + 
  ggtitle("Online activity across postcodes Germany") + 
  scale_fill_viridis_c(direction = -1, trans = "log", na.value="white", name = "Clicks") +
  coord_sf()

