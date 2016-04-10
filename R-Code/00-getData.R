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


# Save object -------------------------------------------------------------

save(collections, file = "R-Code/collections.RData")
rm(list = ls())
