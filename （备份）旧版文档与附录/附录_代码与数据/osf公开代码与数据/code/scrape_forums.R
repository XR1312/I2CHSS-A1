# scrape top 500 online forums Germany

datalist = list()

for(i in c(1:25)) {
  url <- paste("https://www.beliebte-foren.de/top500_nach_besucher/",as.character(i))
  
  forums <- url %>% 
    xml2::read_html() %>%
    html_nodes(xpath='/html/body/div/div/div/div/div[1]/table') %>%
    html_table()
  
  forums <- forums[[1]]
  names(forums)[2] <- "forum"
  forums$forum <- sub('\\..*', '', forums$forum)
  
  datalist[[i]] <- forums
  
}

forums_df = do.call(rbind, datalist)

# write_xlsx(forums_df, "data/temp/forums.xlsx")

