# Adventure Deck Customizer

Version: 0.5.20200906

## Overview

This application is a tiny program to help you customize the official Adventure Deck for Savage Worlds (SW) using Fantasy Grounds (FG).

The program does the following:

* Convert original images to jpg files of three different sizes: first one for thumbnails, second one for quick preview and third one for full detail images.
* Create extension for your custom decks.
* Create module for showing full detail images for your cards.

## Requirements

* Fantasy Grounds installed.
* Adventure Deck installed.
* One or more SW decks. You need to scan the decks or create your own cards.
* R language, a statistical and graphics program; you can download and install from www.r-project.org
* Imagemagick, a program to manipulate images; you can download It from www.imagemagick.org or install it inside R (see below).
* Some R packages are required for the function to work. See below.
* The zip file of this repository.
* An excel file containing the name and effects of each card in the decks.

## Notes on installation

### How to install imagemagick inside R:

```
if(!require(installr)) install.packages("installr")
install.ImageMagick()
```

### How to install required R packages:

```
if(!require(tidyverse)) install.packages("tidyverse")
if(!require(readxl)) install.packages("readxl")
if(!require(magick)) install.packages("magick")
```

## Format of the excel file

Must have 4 columns:

* deckname: the name of the deck the card belongs to.
* default: Whether the deck must be enabled by default in FG options (yes/no).
* filename: the file name of the image file depicting the card.
* name: the name of the card.
* effect: the effect of the card, to be printed in the details of the full detail card window.

Note on the format: 

* You have to escape special characters: \" instead of ", and use html codes: &amp; instead of &.
* Path to files must be relative to i.images (see parameters) directory, using '/' dir separator (as in linux), instead of windows' '\'.

## How to run the program

Fill in an excel file with the columns deckname,default,filename,name,effect. Write down the details of your cards, one per row.

Prepare the images in any format, and put in any directory, be sure the excel filename points to the right image file and directory.

Download this repository using the Clone or download button, decompress it to any directory and write it down to use later (path/to/the/decompressed.repository).

Load the three required packages:

```
library(tidyverse)
library(magick)
library(readxl)
```

Set the working directory to your excel file:

```
setwd("path/to/the/excel.and.image.folder")
```

Alternatively, if you are using Rstudio (a gui frontend for R Language), you can create a script to execute the program and use the following command to set the working directory to the directory where the script is located.

```
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
```

Load the function.

```
source("path/to/the/decompressed.repository/deck.customizer.R")
```

Run the function.

```
deck.customizer("exampledeck.xlsx", "exampleimages", "path/to/the/decompressed.repository")
```

Where first parameter is the name of the excel file and second parameter is the directory where images are located.
After this command the program creates two files, ‘Adventure Deck - customized.ext’ and ‘Adventure Deck - customized.mod’. The first one must be copied to the extension directory of FG and the second one to modules.

## More parameters of the function

* i.definitions (no default): name of the excel file.
* i.images (no default): name of the directory where the images are located.
* i.function.directory (defaults to "."): name of the directory where the function files are located.
* i.extname (defaults to "Adventure Deck - customized"): name of the extension and the ext and mod files created.
* i.zip.internal (defaults to FALSE): T/F, whether the internal compression command is available. Use this if you are using Linux or if you are sure your windows OS has the zip.exe command available.
* i.delete.temp (defaults to FALSE): T/F, whether to delete the temporary folder tempfiles after compressing the extension and module.
* i.unity (defaults to TRUE): whether to create the deck for Unity (T) or Classic (F). There are different encodings for ext and mod files in FGU and FGC, so you have to use different versions for one or the other.
* i.noext (defaults to FALSE): whether to create the ext file or not. If you what a catalog of images for yout players to browse, then do not create the ext, and use only the mod file.
