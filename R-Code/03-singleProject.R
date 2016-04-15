## 03-singleProject.R
# This scripts reproduces some of the Analyses for singular projects.
#
# Copyright Antoine Lizee 2016 - see LICENSE or README file at the repository level.

selProject <- "rephetio"

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
pubs <- get(load("R-Code/pubs.RData")) %>% 
  filter(project == selProject) %>% 
  droplevels()


# Profile plots ------------------------------------------------------------

colors <- suppressWarnings(
  colorRampPalette(RColorBrewer::brewer.pal(12, "Set1")) # "Set1", "Accent"
)
m6breaks <- seq(as.Date("2015-01-01"), max(pubs$date), by = "6 months")
m1breaks <- seq(as.Date("2014-12-01"), max(pubs$date), by = "1 month")

d0N <- suppressWarnings(density(as.numeric(pubs$date), 
                                weight = pubs$N,
                                adjust = 0.2, cut = 0))
r0N <- length(as.numeric(d0N$x)) / diff(range(d0N$x))

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
       colour = "username, in order of sign-up", fill = "username, in order of sign-up")

# Stream chart
ggStreamPpl <- pubsPpl %>% filter(!un %in% c("dhimmel")) %>% 
  group_by(x) %>% 
  arrange(un) %>% 
  mutate(cy = cumsum(y),
         ymax = cy - sum(y)/2,
         ymin = dplyr::lag(ymax, default = -sum(y)/2)) %>% 
  ungroup() %>% 
  ggplot() +
  geom_ribbon(aes(x = x, ymin = ymin, ymax = ymax, 
                  group = un, fill = un), 
              alpha = 0.9, size = 0.1, colour = "grey95") +
  scale_x_date(breaks = m6breaks,
               minor_breaks = m1breaks,
               labels = scales::date_format("%Y-%b")) +
  scale_fill_manual(values = colors(length(unique(pubsPpl$un))),
                    guide = guide_legend(reverse = TRUE)) +
  scale_color_manual(values = colors(length(unique(pubsPpl$un))),
                     guide = guide_legend(reverse = TRUE)) +
  scale_y_continuous(breaks = NULL, minor_breaks = NULL, labels = NULL,
                     expand = c(0.01, 0)) +
  theme_perso() + 
  theme_minimal() +
  theme(axis.ticks.y = element_blank(), 
        panel.grid.major.x = element_line(colour = "grey70"),
        panel.grid.minor.x = element_line(colour = "grey98")) +
  labs(x = NULL, y = "Characters written per day",
       colour = "username, in order of sign-up", fill = "username, in order of sign-up")

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
  filter(tot > 5000)
# Plot:
xrange <- range(pubsSumPpl$x)
ggDensSumPPl <- ggplot(pubsSumPpl) +
  geom_area(aes(x = x, y = cumN, group = profile, fill = profile), 
            alpha = 0.9, size = 0.1, colour = "grey95") +
  geom_text(data = pubsSumPplLab,
            aes(label = sprintf("- %s %s", fn, ln), x = x,
                y = yEnd, colour = profile), size = 4.5, hjust = 0) +
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

savePlot(ggDensPPl, filename = "Output/03-evoProfiles")
savePlot(ggStreamPpl, filename = "Output/03-evoStreamProfiles")
savePlot(ggDensSumPPl, filename = "Output/03-evoCumProfiles", w = 8, h = 4)

