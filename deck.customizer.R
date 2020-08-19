# Adventure Deck Customizer for Savage World using Fantasy Grounds
#  + Official Adventure Deck required
#  + Savage Worlds compatible (SWADE)

deck.customizer <- function(i.definitions, i.images, i.function.directory = ".", i.extname = "Adventure Deck - customized", i.zip.internal = FALSE, i.delete.temp = TRUE) {
  if (!i.zip.internal & !file.exists(file.path(i.function.directory, "7z.exe"))) stop("External compressor chosen (i.zip.internal=F) but 7z not found.\nPlace 7z.exe at the same folder of the function.\n")
  
  temp1 <- data.frame(filename = list.files(i.images, pattern = "*.png|*.jpg|*.gif|*.bmp|*.tif", full.names = F, recursive = T), stringsAsFactors = F) %>%
    mutate(
      pngname = basename(filename), dirname = dirname(filename), basename = tools::file_path_sans_ext(pngname),
      filenamelow = tolower(filename)
    )
  temp2 <- read_excel(i.definitions)
  temp2 <- temp2 %>%
    setNames(tolower(names(temp2))) %>%
    mutate(filenamelow = tolower(filename)) %>%
    select(-filename)
  
  temp3 <- temp2 %>%
    select(deckname, default) %>%
    group_by(deckname, default) %>%
    summarise(ene=n()) %>%
    arrange(deckname, -ene) %>%
    group_by(deckname) %>%
    slice(1) %>%
    ungroup() %>%
    select(-ene) %>%
    mutate(
      dummy1 = str_replace_all(tolower(deckname), "[^[:alnum:]]", ""),
      deckid = make.unique(substr(dummy1, 1, 3), sep = "")
    ) %>%
    select(-dummy1)
  datos <- temp1 %>%
    inner_join(select(temp2, -default), by = "filenamelow") %>%
    inner_join(temp3, by = "deckname") %>%
    mutate(tagname = paste(deckid, tolower(tools::file_path_sans_ext(pngname)), sep = "_"),
           default=ifelse(tolower(default)=="yes","on","off"))
  rm("temp1", "temp2", "temp3")

  if (dir.exists("tempfiles")) unlink("tempfiles", recursive = T)
  if (!dir.exists("tempfiles")) dir.create("tempfiles")
  dir.create("tempfiles/ext")
  dir.create("tempfiles/mod")
  dir.create("tempfiles/ext/graphics")
  dir.create("tempfiles/ext/graphics/54x75")
  dir.create("tempfiles/ext/graphics/149x208")
  dir.create("tempfiles/mod/images")
  dir.create("tempfiles/mod/images/465x650")

  for (idir in datos %>%
    filter(dirname != ".") %>%
    select(dirname) %>%
    distinct() %>%
    pull(dirname)) {
    dir.create(file.path("tempfiles/ext/graphics/54x75", idir))
    dir.create(file.path("tempfiles/ext/graphics/149x208", idir))
    dir.create(file.path("tempfiles/mod/images/465x650", idir))
  }


  cat("+ STEP ONE: Converting images\n")

  for (i in 1:NROW(datos)) {
    cat("\tConverting ", datos$filename[i], "\n")
    image1 <- image_read(file.path(i.images, datos$filename[i]))
    image2 <- image_scale(image1, "54x75!")
    image3 <- image_scale(image1, "149x208!")
    image4 <- image_scale(image1, "465x650!")
    image_write(image2, path = paste0(file.path("tempfiles/ext/graphics/54x75", datos$dirname[i], datos$basename[i]), ".jpg"), format = "jpg")
    image_write(image3, path = paste0(file.path("tempfiles/ext/graphics/149x208", datos$dirname[i], datos$basename[i]), ".jpg"), format = "jpg")
    image_write(image4, path = paste0(file.path("tempfiles/mod/images/465x650", datos$dirname[i], datos$basename[i]), ".jpg"), format = "jpg")
  }

  cat("+ STEP TWO: Creating the extension\n")

  cat("\tCreating \'extension.xml\'\n")

  lines <- c(
    "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>",
    "<root version=\"3.3\">",
    "\t<properties>",
    paste0("\t\t<name>Feature: ", i.extname, "</name>"),
    "\t\t<author>Created using deckgenerator by Viriato139ac, 2020</author>",
    "\t\t<description>Customized Adventure Deck</description>",
    "\t\t<ruleset>",
    "\t\t\t<name>SavageWorlds</name>",
    "\t\t</ruleset>",
    "\t\t<dependency>",
    "\t\t\t<name>AdventureDeck</name>",
    "\t\t</dependency>",
    "\t\t<exclusiongroup>AdventureDeckConfig</exclusiongroup>",
    "\t\t<loadorder>30</loadorder>",
    "\t</properties>",
    paste0("\t<announcement text = \"",i.extname,", a customized Adventure Deck created using deckgenerator by Viriato139ac, 2020\" icon =\"vir_logo\" Font = \"systemfont\" />"),
    "\t<base>",
    "\t\t<includefile source=\"graphics.xml\" />",
    "\t\t<script name=\"MyCustom_AdventureDeck\" file=\"adventuredeck.lua\" />",
    "\t</base>",
    "</root>"
  )
  fileConn <- file(file.path("tempfiles/ext", "extension.xml"))
  writeLines(lines, fileConn)
  close(fileConn)

  cat("\tCreating \'graphics.xml\'\n")

  lines <- c(
    "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>",
    "<root version=\"3.3\">",
    "\t<icon name=\"vir_logo\" file=\"vir_logo.png\" />"
  )
  for (i in 1:NROW(datos)) {
    lines <- c(
      lines,
      paste0("\t<icon name=\"", datos$tagname[i], "\" file=\"graphics/149x208/", ifelse(datos$dirname[i] == ".", datos$basename[i], file.path(datos$dirname[i], datos$basename[i])), ".jpg\" />"),
      paste0("\t<icon name=\"", datos$tagname[i], "-drag\" file=\"graphics/54x75/", ifelse(datos$dirname[i] == ".", datos$basename[i], file.path(datos$dirname[i], datos$basename[i])), ".jpg\" />")
    )
  }
  lines <- c(lines, "</root>")

  fileConn <- file(file.path("tempfiles/ext", "graphics.xml"))
  writeLines(lines, fileConn)
  close(fileConn)

  cat("\tCreating \'adventuredeck.lua\'\n")

  decks <- datos %>%
    select(deckname, deckid, default) %>%
    distinct() %>%
    arrange(desc(default), deckname)

  lines <- character()

  for (i in 1:NROW(decks)) {
    temp1 <- datos %>%
      filter(deckid == decks$deckid[i])
    lines <- c(
      lines,
      paste0("CustomDeck_", decks$deckid[i], " = {")
    )
    for (j in 1:NROW(temp1)) {
      lines <- c(
        lines,
        paste0(
          "\t[\"", temp1$tagname[j], "\"] = { name = \"", temp1$name[j], "\", effect = \"",
          temp1$effect[j], "\", image = \"adventuredeck.cards.", temp1$tagname[j], "@", i.extname, "\"}",ifelse(j==NROW(temp1),"",",")
        )
      )
    }
    lines <- c(
      lines,
      "}"
    )
    rm("temp1")
  }

  lines <- c(
    lines,
    "AdventureDecks = {"
  )

  for (i in 1:NROW(decks)) {
    lines <- c(
      lines,
      paste0("\t{ key = \"", str_replace_all(toupper(decks$deckname[i]), "[^[:alnum:]]", ""), "\", description = \"", decks$deckname[i], "\", cards = ", paste0("CustomDeck_", decks$deckid[i]), ", default = \"",decks$default[i],"\" },")
    )
  }

  lines <- c(
    lines,
    "}",
    "function onInit()",
    "\tAdventureDeckConfigManager.setConfig({",
    "\t\tAdventureDecks = AdventureDecks",
    "\t})",
    "end"
  )

  fileConn <- file(file.path("tempfiles/ext", "adventuredeck.lua"))
  writeLines(lines, fileConn)
  close(fileConn)

  cat("\tCopying \'vir_logo.png\'\n")
  file.copy(file.path(i.function.directory, "vir_logo.png"), "tempfiles/ext/vir_logo.png")

  cat("+ STEP THREE: Creating the module\n")

  cat("\tCreating \'definition.xml\'\n")

  lines <- c(
    "<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>",
    "<root version=\"3.3\">",
    paste0("\t<name>", i.extname, "</name>"),
    "\t<category>Savage Worlds</category>",
    "\t<author>Viriato139ac</author>",
    "\t<ruleset>SavageWorlds</ruleset>",
    "</root>"
  )

  fileConn <- file(file.path("tempfiles/mod", "definition.xml"))
  writeLines(lines, fileConn)
  close(fileConn)

  cat("\tCreating \'thumbnail.png\'\n")

  file.copy(file.path(i.function.directory, "vir_logo.png"), "tempfiles/mod/thumbnail.png")

  cat("\tCreating \'client.xml\'\n")

  counter1 <- 0
  
  lines <- c(
    "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>",
    "<root version=\"3.3\">",
    "\t<library>",
    "\t\t<adventuredeckextracards static=\"true\">",
    paste0("\t\t\t<name type=\"string\">", i.extname, "</name>"),
    "\t\t\t<categoryname type=\"string\">Adventure Deck</categoryname>",
    "\t\t\t<entries>")
  
  for (decki in 1:NROW(decks)){
    
    lines <- c(lines,
               paste0("\t\t\t\t<_",substr(counter1 + 100, 2, 3),"_card_list>"),
               "\t\t\t\t\t<librarylink type=\"windowreference\">",
               "\t\t\t\t\t\t<class>sw_referenceindex</class>",
               "\t\t\t\t\t\t<recordname>..</recordname>",
               "\t\t\t\t\t</librarylink>",
               paste0("\t\t\t\t\t<name type=\"string\">&#407;&#407;&#407; ", toupper(decks$deckname[decki]), " &#407;&#407;&#407;</name>"),
               "\t\t\t\t\t<index>"
    )
    
    decksi <- datos %>%
      filter(deckname==decks$deckname[decki])
    
    for (j in 1:NROW(decksi)) {
      lines <- c(
        lines,
        paste0("\t\t\t\t\t\t<_", substr(j + 1000, 2, 4), "_", decksi$tagname[j], ">"),
        paste0("\t\t\t\t\t\t\t<name type=\"string\">", decksi$name[j], "</name>"),
        "\t\t\t\t\t\t\t<listlink type=\"windowreference\">",
        "\t\t\t\t\t\t\t\t<class>imagewindow</class>",
        paste0("\t\t\t\t\t\t\t\t<recordname>adventuredeck.cards.", decksi$tagname[j], "@", i.extname, "</recordname>"),
        "\t\t\t\t\t\t\t</listlink>",
        paste0("\t\t\t\t\t\t</_", substr(j + 1000, 2, 4), "_", decksi$tagname[j], ">")
      )
    }
    
    lines <- c(
      lines,
      "\t\t\t\t\t</index>",
      paste0("\t\t\t\t</_",substr(counter1 + 100, 2, 3),"_card_list>")
    )
    counter1 <- counter1 +1
    
    for (j in 1:NROW(decksi)) {
      lines <- c(
        lines,
        paste0("\t\t\t\t<_",substr(counter1 + 100, 2, 3),"_card_", substr(j + 1000, 2, 4), "_", decksi$tagname[j], ">"),
        paste0("\t\t\t\t\t<name type=\"string\">&#407; ", decksi$name[j], "</name>"),
        "\t\t\t\t\t<librarylink type=\"windowreference\">",
        "\t\t\t\t\t\t<class>imagewindow</class>",
        paste0("\t\t\t\t\t\t<recordname>adventuredeck.cards.", decksi$tagname[j], "@", i.extname, "</recordname>"),
        "\t\t\t\t\t</librarylink>",
        paste0("\t\t\t\t</_",substr(counter1 + 100, 2, 3),"_card_", substr(j + 1000, 2, 4), "_", decksi$tagname[j], ">")
      )
    }
    counter1 <- counter1 +1
  }
  
  lines <- c(
    lines,
    "\t\t\t</entries>",
    "\t\t</adventuredeckextracards>",
    "\t</library>",
    "\t<adventuredeck>",
    "\t\t<cards>"
  )
  
  for (i in 1:NROW(datos)) {
    lines <- c(
      lines,
      paste0("\t\t\t<", datos$tagname[i], ">"),
      paste0("\t\t\t\t<name type=\"string\">", datos$name[i], "</name>"),
      paste0("\t\t\t\t<cardId type=\"string\">", datos$tagname[i], "</cardId>"),
      "\t\t\t\t<type type=\"string\">adventurecard</type>",
      "\t\t\t\t<image type=\"image\">",
      paste0("\t\t\t\t\t<bitmap>images/465x650/", ifelse(datos$dirname[i] == ".", datos$basename[i], file.path(datos$dirname[i], datos$basename[i])), ".jpg</bitmap>"),
      "\t\t\t\t</image>",
      paste0("\t\t\t</", datos$tagname[i], ">")
    )
  }
  
  lines <- c(
    lines,
    "\t\t</cards>",
    "\t</adventuredeck>",
    "\t</root>"
  )
  
  fileConn <- file(file.path("tempfiles/mod", "client.xml"))
  writeLines(lines, fileConn)
  close(fileConn)

  # cat("\tCreating \'common.xml\'\n")
  # file.copy(file.path("tempfiles/mod", "client.xml"), file.path("tempfiles/mod", "common.xml"))

  cat("+ STEP FOUR: Compressing files\n")

  i.function.directory <- tools::file_path_as_absolute(i.function.directory)

  my_wd <- getwd() # save your current working directory path
  dest_path <- "tempfiles/ext"
  setwd(dest_path)
  if (i.zip.internal) {
    files <- list.files(recursive = T)
    zip(zipfile = paste0(i.extname, ".ext"), files = files)
  } else {
    system(paste0("\"", file.path(i.function.directory, "7z.exe"), "\" a -tzip \"", i.extname, ".ext\" *"), intern = T)
  }
  setwd(my_wd) # reset working directory path

  my_wd <- getwd() # save your current working directory path
  dest_path <- "tempfiles/mod"
  setwd(dest_path)
  if (i.zip.internal) {
    files <- list.files(recursive = T)
    zip(zipfile = paste0(i.extname, ".mod"), files = files)
  } else {
    system(paste0("\"", file.path(i.function.directory, "7z.exe"), "\" a -tzip \"", i.extname, ".mod\" *"), intern = T)
  }
  setwd(my_wd) # reset working directory path

  file.copy(from = paste0(file.path("tempfiles/mod", i.extname), ".mod"), to = paste0(file.path(getwd(), i.extname), ".mod"), overwrite = T)
  file.copy(from = paste0(file.path("tempfiles/ext", i.extname), ".ext"), to = paste0(file.path(getwd(), i.extname), ".ext"), overwrite = T)

  if (i.delete.temp) unlink("tempfiles", recursive = T)
}
