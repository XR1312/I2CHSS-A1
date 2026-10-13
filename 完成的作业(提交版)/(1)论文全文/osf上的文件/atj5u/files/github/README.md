# Mapping the Deliberative Potential of a Political Online Ecosystem with Digital Trace Data
https://osf.io/preprints/socarxiv/68udg/

This repository consists of the following R scripts:

## Meta Scripts
- `tracking_packages.R` (installs relevant packages, called in various scripts)
- `scrape_forums.R` (was used to compile part of the dictionary (scraping the top forums in Germany) for the automated filtering of URLs for politically relevant topics)

## 1. Preprocessing
`1_tracking_deliberation_preprocessing.R`
- includes the combination of URL tracking data with survey data 

`1_demography_descr.R`
- describe sample
- plot distribution of activity on map

`1_political_filtering.R`
- runs the automated filtering run to select politically relevant sites (run overnight!)
- groups selected clicks to domains for manual cross validation (really political content?) + coding of information, communication, participation

## 2. Measuring Deliberative Potential 
`2_measurement_deliberation_prep.R`
- combine manually coded website infrastructure (information, communication, participation) with preprocessed relevant clicks (incl. matched survey data)
- calculates isolation measure with site network
- calculates inclusivity & heterogeneity with diversity index

`2_measurement_description.R`
- creates deliberative feature descriptive graphs
- correlation plot of features

`2_measurement_deliberation_LCA.R`
- runs latent class segmentation analysis (LCA) (3 and 2 class solutions; split half validation; removing incl. / het. criteria validation)
- assigns websites to classes and creates membership table
- plots network with classes

`2_application_deliberation_prep.R`
- integrates LCA results with politically relevant clicks and overall tracking data
- compiles person level engagement metrics for classes and social media vs. news sites

`2_application_deliberation.R`
- computes duration / click ratios
- engagement density plots (clicks and duration, total and baseline corrected)
- creates engagement density small multiples plots for gender, age and education
