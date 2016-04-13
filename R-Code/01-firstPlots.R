## 01-firstPlots.R
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
pubs <- get(load("R-Code/pubs.RData"))


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

savePlot(ggCounts, filename = "Output/counts_raw")
savePlot(ggLCounts, filename = "Output/counts")


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
  theme_perso() +
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
r0 <- length(as.numeric(d0$x)) / diff(range(d0$x))
# Compute the densities per group & plot it
ggDensDate <- pubs %>% 
  group_by(project) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), bw = bin,
              weight = .$weight,
              from = min(d0$x), to = max(d0$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y / r0)
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
  theme_perso() +
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
r0N <- length(as.numeric(d0N$x)) / diff(range(d0N$x))
ggDensChar <- pubs %>% 
  group_by(project) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = bin, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y / r0N)
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
  theme_perso() +
  labs(x = NULL, y = "Number of characters written per day")

savePlot(ggHistChar, filename = "Output/evoHistChar")
savePlot(ggDensChar, filename = "Output/evoDensChar")
  

# Look at users -----------------------------------------------------------

colors <- suppressWarnings(
  colorRampPalette(RColorBrewer::brewer.pal(12, "Set1")) # "Set1", "Accent"
)
m1breaks <- seq(as.Date("2014-05-01"), max(pubs$date), by = "1 month")

# character activity
pubsPpl <- pubs %>% 
  mutate(un = reorder(un, fields.profile, unique)) %>% 
  group_by(un) %>%
  mutate(tot = sum(N)) %>% 
  filter(tot > 1000) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = 30, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y / r0N)
  })
# Small detail: we need to break up the data and the plot here because of the scale_manual. 
# Indeed, since we need to specify the colors manually (due to the lack of scale_brewer_n()
# or something along these lines.). drop = FALSE would work but is problematic for the legend.
ggDensPPl <-  ggplot(pubsPpl) +
  geom_area(aes(x = x, y = y, group = un, fill = un, color = un), 
            alpha = 0.4, size = 0.5) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = scales::date_breaks("1 month"),
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(unique(pubsPpl$un))),
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(values = colors(length(unique(pubsPpl$un))),
                     guide = guide_legend(reverse = TRUE)) +
  theme_perso() +
  labs(x = NULL, y = "Characters written per day",
       colour = "username, in order of apparition", fill = "username, in order of apparition")


# character cumulative activity
pubsSumPpl <- pubs %>% 
  group_by(profile, fn, ln, un) %>%
  mutate(tot = sum(N)) %>% 
  filter(tot > 500) %>% 
  do({
    dd <- suppressWarnings(
      density(as.numeric(.$date), 
              bw = 7, weight = .$N, 
              from = min(d0N$x), to = max(d0N$x))
    )
    data.frame(x = as.Date(dd$x, "1970-01-01"), y = dd$y / r0N, tot = .$tot[1])
  }) %>% 
  arrange(x) %>% 
  # mutate(cumN = log1p(cumsum(y)) / log(10)) %>% 
  # mutate(cumN = asinh(cumsum(y) / 1000)) %>% 
  mutate(cumN = sqrt(cumsum(y))) %>% # Most easily interpreable
  ungroup()
# Create labels
pubsSumPplLab <- pubsSumPpl %>% 
  group_by(profile) %>% 
  summarize_each(funs(last)) %>% 
  arrange(profile) %>% 
  mutate(yEnd = cumsum(cumN) - cumN/2) %>% 
  filter(tot > 4000)
# Plot:
xrange <- range(pubsSumPpl$x)
ggDensSumPPl <- ggplot(pubsSumPpl) +
  geom_area(aes(x = x, y = cumN, group = profile, fill = profile), 
            alpha = 0.9, size = 0.1, colour = "grey95") +
  geom_text(data = pubsSumPplLab,
            aes(label = sprintf("- %s %s", fn, ln), x = x,
                y = yEnd, colour = profile), size = 4, hjust = 0) +
  geom_text(data = pubsSumPplLab,
            aes(label = sprintf("%.1fK ", tot/1000),  x = x,
                y = yEnd), colour = "black", size = 4, hjust = 1) +
  scale_x_date(breaks = m6breaks,
               minor_breaks = m1breaks,
               labels = scales::date_format("%Y-%b"), 
               limits = c(xrange[1], xrange[2] + 0.3 * diff(xrange))) +
  scale_fill_manual(values = colors(length(levels(pubsSumPpl$profile))),
                    guide = guide_legend(reverse = TRUE), drop = FALSE) +
  scale_color_manual(values = colors(length(levels(pubsSumPpl$profile))),
                     guide = guide_legend(reverse = TRUE), drop = FALSE) +
  scale_y_continuous(breaks = NULL, minor_breaks = NULL, labels = NULL,
                     expand = c(0.01, 0)) +
  theme_perso() + 
  theme_minimal() +
  theme(axis.ticks.y = element_blank(), 
        panel.grid.major.x = element_line(colour = "grey70"),
        panel.grid.minor.x = element_line(colour = "grey98")) +
  labs(x = NULL, y = "Total characters written per user (sqrt)") +
  guides(colour = "none", fill = "none")

savePlot(ggDensPPl, filename = "Output/evoProfiles")
savePlot(ggDensSumPPl, filename = "Output/evoCumProfiles")


