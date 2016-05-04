## 00-getData.R
# This scripts loads the json files retrieved from the Thinklab wedsite.
#
# Copyright Antoine Lizee 2016 - see LICENSE or README file at the repository level.

library(dplyr)
# install.packages(c("jsonlite"))

# Get files ---------------------------------------------------------------

dataDir <- "Data/exported/"
projectFiles <- dir(path = dataDir, pattern = "*.json", full.names = TRUE)
projectNames <- sub("^.*\\/(.*)\\.json.*$", "\\1", projectFiles)

projectDatas <- lapply(projectFiles, jsonlite::fromJSON, flatten = TRUE)
names(projectDatas) <- projectNames


# Unpack dataframes --------------------------------------------------

collectionNames <- names(projectDatas[[1]])
collectionNames <- collectionNames[!grepl("retrieved", collectionNames)]
collections <- sapply(collectionNames,
                      function(cN) {
                        # Get all dataframes for this collection
                        ldf <- sapply(projectNames, function(pN) {
                          projectDatas[[pN]][[cN]]
                        }, simplify = FALSE)
                        # Bind them
                        bind_rows(ldf, .id = "project")
                      })


# Some corrections --------------------------------------------------------

collections$notes$fields.published <- collections$notes$fields.added


# Prepare publication table -----------------------------------------------
# Isolate "publications"

pubs <- list(
  comments = collections$comments %>% 
    select(project, fields.published, fields.profile, fields.body_md),
  notes = collections$notes %>% 
    select(project, fields.published, fields.profile, fields.body_md),
  threads = collections$threads %>% 
    select(project, fields.published, fields.profile)
) %>% bind_rows(.id = "type")

# Preprocessing
pubs <- pubs %>% 
  mutate(type = relevel(factor(type), "threads"),
         project = reorder(factor(project), project, length),
         profile = factor(fields.profile),
         time = as.POSIXct(fields.published),
         date = as.Date(time),
         weight = 4 - as.numeric(type), # threads = 3, comments = 2, notes = 1
         N = nchar(fields.body_md)) %>% 
  left_join(collections$profiles %>% 
              select(-project, fields.profile = pk, 
                     fn = fields.first_name, ln = fields.last_name, 
                     un = fields.username) %>% distinct)

# Save objects -------------------------------------------------------------

save(collections, file = "R-Code/collections.RData")
save(pubs, file = "R-Code/pubs.RData")
write.csv(pubs, "Output/pubs.csv")

rm(list = ls())
