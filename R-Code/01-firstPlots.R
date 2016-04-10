## 00-firstPlots.R
# This scripts create the first plots for the analysis of the Thinklab activity.
#
# Copyright Antoine Lizee 2016 - see LICENSE or README file at the repository level.


# Setup -------------------------------------------------------------------

# Packages
library(dplyr)
library(ggplot2)

# Helpers
source("R-Code/H-ggplotTheme.R")


# Load & prepare data -----------------------------------------------------

# Script to generate new version of the data.
# source("R-Code/00-getData.R") 

collections <- get(load("R-Code/collections.RData"))

# Isolate "publications"
pubs <- list(
  comments = collections$comments %>% 
    select(project, fields.published, fields.profile, fields.body_md),
  notes = collections$notes %>% 
    select(project, fields.published, fields.profile, fields.body_md),
  threads = collections$threads %>% 
    select(project, fields.published, fields.profile)
) %>% bind_rows(.id = "type")
# Prep
pubs <- pubs %>% 
  mutate(type = relevel(factor(type), "threads"),
         project = reorder(factor(project), project, length),
         time = as.POSIXct(fields.published),
         date = as.Date(time),
         weight = 4 - as.numeric(type), # threads = 3, comments = 2, notes = 1
         N = nchar(fields.body_md))


# Quick overview -------------------------------------------------------

ggCounts <- pubs %>% 
  ggplot(aes(x = type, color = type, fill = type)) +
  geom_bar() +
  facet_wrap( ~ project, nrow = 1) +
  theme_perso(angle = 45, base_size = 8) +
  labs(y = "Number of events since start of Thinklab", 
       x = NULL, labs = "Publication counts, per type and project") +
  guides(colour = "none", fill = "none")

ggLCounts <- ggCounts + scale_y_log10()

ggsave(ggCounts, filename = "Output/counts_raw.pdf", w = 10, h = 5)
ggsave(ggLCounts, filename = "Output/counts.pdf", w = 10, h = 5)


# Evolution ---------------------------------------------------------------

colors <- suppressWarnings(
  colorRampPalette(RColorBrewer::brewer.pal(12, "Accent")) # "Set1"
)

## Histograms
bin = 365.25 / 23 # 1 month
ggHistDate <- pubs %>% 
  ggplot(aes(x = date)) +
  geom_histogram(aes(fill = project, weight = weight),
                 binwidth  = bin, origin = min(as.numeric(pubs$date)) - bin/2,
                 color = "black", alpha = 0.6) +
  scale_x_date(breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Weighted number of events per week") +
  # Fake legend...
  geom_point(aes(alpha = type), x = 1, y = 1) +
  scale_alpha_manual("Weights", values = c(1, 0.99, 0.98), 
                     labels = c("threads: 3", "comments: 2", "notes: 1")) +
  guides(fill = guide_legend(order = 1), colour = guide_legend(order = 1),
         alpha = guide_legend(keywidth = 0,
                              override.aes = list(fill = NA, color = NA))) + 
  theme(legend.key = element_blank())

## Show density
# Compute a global one to get the parameters
d0 <- suppressWarnings(density(as.numeric(pubs$date), 
                               weight = pubs$weight,
                               adjust = 1, cut = 0))
# Compute the densities per group & plot it
ggDensDate <- pubs %>% 
  group_by(project, type) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), bw = bin,
              weight = .$weight,
              from = min(d0$x), to = max(d0$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  # Plot:
  ggplot() +
  geom_area(aes(x = x, y = y, group = project, fill = project, color = project), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = scales::date_breaks("6 month"),
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(values = colors(length(levels(pubs$project))),
                     guide = guide_legend(reverse = TRUE)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Number of weighted contributions per day") +
  # Fake legend...
  geom_point(aes(alpha = type), x = 1, y = 1) +
  scale_alpha_manual("Weights", values = c(1, 0.99, 0.98), 
                     labels = c("threads: 3", "comments: 2", "notes: 1")) +
  guides(fill = guide_legend(order = 1), colour = guide_legend(order = 1),
         alpha = guide_legend(keywidth = 0,
                              override.aes = list(fill = NA, color = NA))) + 
  theme(legend.key = element_blank())

## Look at the character level
# Hist
bin = 7
ggHistChar <- pubs %>% 
  ggplot(aes(x = date)) +
  geom_histogram(aes(fill = project, weight = N),
                 binwidth  = bin, origin = min(as.numeric(pubs$date)) - bin/2,
                 color = "black", alpha = 0.6) +
  scale_x_date(breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Characters written per week")
# Density
d0N <- suppressWarnings(density(as.numeric(pubs$date), 
                                weight = pubs$N,
                                adjust = 0.2, cut = 0))
ggDensChar <- pubs %>% 
  group_by(project) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = 7, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  ggplot() +
  geom_area(aes(x = x, y = y, group = project, fill = project, color = project), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = scales::date_breaks("6 month"),
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(values = colors(length(levels(pubs$project))),
                     guide = guide_legend(reverse = TRUE)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Number of Character written per day")

ggsave(ggHistDate, filename = "Output/evoHist.pdf", w = 12, h = 8)
ggsave(ggDensDate, filename = "Output/evoDens.pdf", w = 12, h = 8)
ggsave(ggHistChar, filename = "Output/evoHistChar.pdf", w = 12, h = 8)
ggsave(ggDensChar, filename = "Output/evoDensChar.pdf", w = 12, h = 8)
  

