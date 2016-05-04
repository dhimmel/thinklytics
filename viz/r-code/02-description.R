## 02-first Numbers
# Output quick numbers to describe features of our datasets
#
# Copyright Antoine Lizee 2016

# Setup -------------------------------------------------------------------

# Packages
library(dplyr)
library(ggplot2)

# Helpers
source("R-Code/H-ggplot.R")


# Load & prepare data -----------------------------------------------------

collections <- get(load("R-Code/collections.RData"))
pubs <- get(load("R-Code/pubs.RData"))


# Extracting DOIs ---------------------------------------------------------

doiRE <- "@10[.][0-9]{3,}(?:[.][0-9]+)*[/.][^\\][:space:]]+"
st <- c("piuhpiuh", "poijpoij [@10.7887.g7] opij")
regmatches(st, gregexpr(doiRE, text = st, perl = TRUE))

dois <- pubs %>% 
  group_by(project, type) %>% 
  do (
    data.frame(
      doi = unlist(regmatches(.$fields.body_md, gregexpr(doiRE, .$fields.body_md, perl = TRUE))),
      stringsAsFactors = FALSE)
  ) %>% ungroup () %>% 
  distinct() 

cat("\n\n## Number of doi citations in text, per project and type:\n")
dois %>% count(project, type) %>% as.data.frame %>% print
cat("\n\n## Number of doi citations in text, per project:\n")
dois %>% select(-type) %>% distinct() %>% count(project, sort = TRUE) %>% as.data.frame %>% print


# Showing users -----------------------------------------------------------

cat("\n\n## Number of doi citations in text, per project:\n")
pubs %>% distinct(project, profile) %>% 
  count(project, sort = TRUE) %>% as.data.frame %>% print



