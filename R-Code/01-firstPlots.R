## 00-firstPlots.R
# This scripts create the first plots for the analysis of the Thinklab activity.
#
# Copyright Antoine Lizee 2016 - see LICENSE or README file at the repository level.


# Setup -------------------------------------------------------------------

# Packages
library(dplyr)
library(ggplot2)

# Helpers
source("R-Code/H-ggplot.R")


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
         profile = factor(fields.profile),
         time = as.POSIXct(fields.published),
         date = as.Date(time),
         weight = 4 - as.numeric(type), # threads = 3, comments = 2, notes = 1
         N = nchar(fields.body_md)) %>% 
  left_join(collections$profiles %>% 
              select(-project, fields.profile = pk, 
                     fn = fields.first_name, ln = fields.last_name, 
                     un = fields.username) %>% distinct)


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

savePlot(ggCounts, filename = "Output/counts_raw", w = 10, h = 5)
savePlot(ggLCounts, filename = "Output/counts", w = 10, h = 5)


# Evolution ---------------------------------------------------------------

colors <- suppressWarnings(
  colorRampPalette(RColorBrewer::brewer.pal(12, "Accent")) # "Set1", "Accent"
)
m6breaks <- seq(as.Date("2014-07-01"), max(pubs$date), by = "6 months")

## Histograms
bin = 365.25 / 12 # 1 month
ggHistDate <- pubs %>% 
  ggplot(aes(x = date)) +
  geom_histogram(aes(fill = project, weight = weight),
                 binwidth  = bin, origin = min(as.numeric(pubs$date)) - bin/2,
                 color = "black", alpha = 0.6) +
  scale_x_date(breaks = m6breaks,
               labels = scales::date_format("%Y-%b"),
               minor_breaks = scales::date_breaks("1 month")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE, order = 1)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Weighted number of events per month") +
  # Fake legend...
  geom_point(aes(alpha = type), x = 1, y = 1) +
  scale_alpha_manual("Weights", values = c(1, 0.99, 0.98), 
                     labels = c("threads: 3", "comments: 2", "notes: 1")) +
  guides(alpha = guide_legend(keywidth = 0,
                              override.aes = list(fill = NA, color = NA))) + 
  theme(legend.key = element_blank())

## Show density
# Compute a global one to get the parameters
d0 <- suppressWarnings(density(as.numeric(pubs$date), 
                               weight = pubs$weight,
                               adjust = 1, cut = 0))
# Compute the densities per group & plot it
ggDensDate <- pubs %>% 
  group_by(project) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), bw = bin,
              weight = .$weight,
              from = min(d0$x), to = max(d0$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  # mutate(y = sqrt(y)) %>% # Transform for better readability
  # Plot:
  ggplot() +
  geom_area(aes(x = x, y = y, group = project, fill = project, color = project), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE, order = 1)) +
  scale_color_manual(values = colors(length(levels(pubs$project))),
                     guide = guide_legend(reverse = TRUE, order = 1)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Number of weighted contributions per day") +
  # Fake legend...
  geom_point(aes(alpha = rep(c("1","2", "3"), length.out = 5120)), 
             x = 1, y = 1, color = NA) +
  scale_alpha_manual("Weights", values = c(1, 0.99, 0.98), 
                     labels = c("threads: 3", "comments: 2", "notes: 1")) +
  guides(alpha = guide_legend(keywidth = 0,
                              override.aes = list(fill = NA, color = NA))) + 
  theme(legend.key = element_blank())

savePlot(ggHistDate, filename = "Output/evoHist")
savePlot(ggDensDate, filename = "Output/evoDens")


# Look at the character level ---------------------------------------------

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
              bw = bin, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  # mutate(y= sqrt(y)) %>% 
  ggplot() +
  geom_area(aes(x = x, y = y, group = project, fill = project, color = project), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$project))),
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(values = colors(length(levels(pubs$project))),
                     guide = guide_legend(reverse = TRUE)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Number of Character written per day")

savePlot(ggHistChar, filename = "Output/evoHistChar")
savePlot(ggDensChar, filename = "Output/evoDensChar")
  

# Look at users -----------------------------------------------------------

colors <- suppressWarnings(
  colorRampPalette(RColorBrewer::brewer.pal(12, "Set1")) # "Set1", "Accent"
)

# character activity
ggDensPPl <- pubs %>% 
  group_by(profile) %>%
  mutate(tot = sum(N)) %>% 
  filter(tot > 1000) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = 30, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  ggplot() +
  geom_area(aes(x = x, y = y, group = profile, fill = profile, color = profile), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(levels(pubs$profile))),
                    guide = guide_legend(reverse = TRUE), drop = FALSE) +
  scale_color_manual(values = colors(length(levels(pubs$profile))),
                     guide = guide_legend(reverse = TRUE), drop = FALSE) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Cumulative number of Character written per profile")


# character cumulative activity
pubsSumPPl <- pubs %>% 
  group_by(profile, fn, ln, un) %>%
  mutate(tot = sum(N)) %>% 
  filter(tot > 500) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = 7, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y)
  }) %>% 
  arrange(x) %>% 
  # mutate(cumN = log1p(cumsum(y)) / log(10)) %>% 
  # mutate(cumN = asinh(cumsum(y) / 1000)) %>% 
  mutate(cumN = sqrt(cumsum(y))) %>% # Most easily interpreable
  ungroup()

ggDensSumPPl <- ggplot(pubsSumPPl) +
  geom_area(aes(x = x, y = cumN, group = profile, fill = profile), 
            alpha = 0.9, size = 0.1, colour = "grey95") +
  geom_text(data = pubsSumPPl %>% 
              group_by(profile) %>% 
              summarize_each(funs(last)) %>% 
              arrange(profile) %>% 
              mutate(yEnd = cumsum(cumN) - cumN/2) %>% 
              filter(cumN > sqrt(4000)),
            aes(label = fn, y = yEnd, colour = profile), 
            x = max(as.numeric(pubsSumPPl$x)) + 2, size = 5, hjust = 0) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b"), expand = c(0.1, 0)) +
  scale_fill_manual(values = colors(length(levels(pubsSumPPl$profile))),
                    guide = guide_legend(reverse = TRUE), drop = FALSE) +
  scale_color_manual(values = colors(length(levels(pubsSumPPl$profile))),
                     guide = guide_legend(reverse = TRUE), drop = FALSE) +
  scale_y_continuous(labels = function(x) sprintf("%.2g", x*x)) +
  theme_perso(angle = 60) +
  labs(x = NULL, y = "Square root of the Characters written per profile") +
  guides(colour = "none", fill = "none")

savePlot(ggDensPPl, filename = "Output/evoProfiles")
savePlot(ggDensSumPPl, filename = "Output/evoCumProfiles")


