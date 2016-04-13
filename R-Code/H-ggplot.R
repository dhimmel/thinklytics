## H-ggplot.R
# Helper for the ggplot theme mgmt.
#
# Copyright Antoine Lizee 2016

# Helper for theme_bw -----------------------------------------------------

theme_perso <- function(angle = 0, ...) {
  hjust = c(0, 0.5, 1)[(angle >= 0) + (angle > 0) + 1]
  theme_bw(...) + theme(
    strip.background = element_rect(fill = "grey 98", 
                                    colour = "grey50", 
                                    size = 0.5),
    axis.text.x = element_text(angle = angle,
                               hjust = hjust)
  )
}


# Helper for internal --------------------------------------------------

# reproduce bandwith computation in stat_density to 
# change it:
gg_bw <- function(b = 1.5, x) { b/bw.nrd0(x) }


# Helper for saving plots -------------------------------------------------

savePlot <- function(plot, filename, w = 8, h = 5, res = 300) {
  ggsave(filename = paste0(filename, ".pdf"), plot = plot, 
         w = w, h = h)
  ggsave(filename = paste0(filename, ".png"), plot = plot, 
         w = w, h = h, dpi = res)
}
