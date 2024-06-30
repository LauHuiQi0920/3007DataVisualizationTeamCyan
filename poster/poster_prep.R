#| label: library
#| message: false

library(dplyr)
library(tidyverse)
library(readxl)
library(lubridate)
library(DT)
library(sf)
library(knitr)

## -----------------------------------------------------------------------------
#| label: fig-wsj
#| echo: false
#| fig.cap: "Visualization of measles incidence in the United States from
#|   1928 to 2013 by @debold_battling_2015."

include_graphics("imgs/bad_graph.jpeg")
