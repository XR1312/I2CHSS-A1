# Packages

p_needed <- c("tidyverse", 
              
            # data management        
              "readr", 
              "readxl",
              "writexl", 
              "reshape", 
              "gdata", 
              "sf", 
              "urltools", 
              "panelr",
              "stringr",
            
            # scraping
              "rvest",
             
            # visualization
              "ggplot2", 
              "ggraph",
              "ggrepel", 
              "jcolors", 
              "corrplot", 
              "ggcorrplot",
              "gridExtra",
              "ggridges",
             
            # table formatting
              "knitr",
              "xtable", 
              "kableExtra", 
              
            # network
              "igraph", 
            
            # analyses
              "sjPlot",
              "psych",
              "GPArotation",
              "lavaan",
              "Hmisc",  
              "vegan", 
              "poLCA", 
              "tidyLPA"
)
              

packages <- rownames(installed.packages())

p_to_install <- p_needed[!(p_needed %in% packages)]
if (length(p_to_install) > 0) {
  install.packages(p_to_install)
}
lapply(p_needed, require, character.only = TRUE)
