if(!require(tidyverse)) install.packages("tidyverse")
if(!require(magick)){
  if(!require(installr)) install.packages("installr")
  install.ImageMagick()
  install.packages("magick")
} 
if(!require(readxl)) install.packages("readxl")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# setwd("/path/to/the/function")

source("deck.customizer.R")

deck.customizer("exampledeck.xlsx", "exampleimages")
