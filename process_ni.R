suppressMessages(require(gdata))

temp <- read.xls("source_data/ni/SAPE_SOA_0114.xls", sheet = 12)
temp <- temp[4:nrow(temp), c(2, 17)]
names(temp) <- c("soa2011", "population")
temp$population <- as.integer(gsub(",", "", temp$population))
temp <- temp[!is.na(temp$population), ]
write.table(temp, "", col.names = FALSE, row.names = FALSE, sep= ",")
