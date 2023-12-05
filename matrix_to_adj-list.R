library(haven)

#read in VDEM countries and border matrix
setwd('~/kellogg/kellogg_r')
VData <- readRDS(file = "VData.rds")  ##make sure to set working directory correctly
countries = sort(unique(VData$country_text_id))
border_matrix <- read_dta("border_mat_condensed.dta")

#build empty array of country-year
years_list <- seq(from = 1901.5, to = 2019.5, by = 2)
cy = list()
for (y in years_list) {
  for (c in countries) {
    cy = append(cy, paste0(c, y))
  }
}
country_year <- array(0, c(length(countries) * length(years_list), length(countries)),
                      dimnames = list(cy, countries))
country_year = as.data.frame(country_year)

#file connection
adj_list_csv_path = "adjacency_list.csv"
file_conn <- file(adj_list_csv_path, "w")


#initialize list
adj_list = list()
for (row_name in rownames(border_matrix)) {
  adj_list[row_name] = list()
}


#convert matrix to adj list csv file
writeLines(paste(unlist(c("Node", "Connections")), collapse = ","), con = file_conn)
for (i in 1:nrow(border_matrix)) {
  connected_nodes <- which(border_matrix[i,] == 1)
  connected_nodes = colnames(border_matrix)[connected_nodes]
  rowname = paste0(substr(rownames(country_year)[[i]], 1, 7), "5")
  print(rowname)
  print(connected_nodes)
  writeLines(paste(c(rowname, connected_nodes), collapse = ","), con = file_conn)
}

close(file_conn)
