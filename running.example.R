library(tidyverse)
library(magick)
library(readxl)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd("path/to/the/decompressed.repository")

source("deck.customizer.R")

deck.customizer("exampledeck.xlsx", "exampleimages")
