setwd('~/kellogg/kellogg_r')

#### build matrix (code copied from original R file) ####
VData <- readRDS(file = "VData.rds")  ##make sure to set working directory correctly
countries = sort(unique(VData$country_text_id))

#get country-year names
years_list <- seq(from = 19015, to = 20195, by = 20)
cy = list()
for (y in years_list) {
  for (c in countries) {
    cy = append(cy, paste0(c, y))
  }
}

#set up country-year x country-year matrix 
country_year <- array(0, c(length(countries) * length(years_list), length(countries)),
                      dimnames = list(cy, countries))

country_year = as.data.frame(country_year)
border_matrix = country_year
########

file_conn <- file("adjacency_list.csv", "r")

#line-by-line data entry
while (length(line <- readLines(file_conn, n = 1)) > 0) {
  if (grepl("5$", line)){
    next
  }
  line = strsplit(line, ",")[[1]]
  country = line[[1]]
  neighbor_list = line[2:length(line)]
  for (neighbor in neighbor_list){
    border_matrix[country, neighbor] = 1 
  }
}

border_matrix = border_matrix[, -ncol(border_matrix)]

write.csv(border_matrix, file = "ntbynmat.csv", row.names = TRUE)

# Close the file connection
close(file_conn)
