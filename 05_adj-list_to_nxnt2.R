library(dplyr)
library(tidyr)

# Constants
WORKING_DIR = "~/kellogg/kellogg_r/11.14"
NEIGHBORS_FILE = "missing_nabes.csv"
VDATA_FILE = "VData.rds"
START_YEAR = 1901
END_YEAR = 2019

# Set working directory
setwd(WORKING_DIR)

# Read VDEM countries and initialize variables
VData <- readRDS(file = VDATA_FILE)
countries <- sort(unique(VData$country_text_id))

# Generate country-year combinations
years_list <- seq(from = START_YEAR + .5, to = END_YEAR + .5, by = 2)
cy <- expand.grid(countries, years_list)
cy <- apply(cy, 1, paste, collapse = "")
country_year <- array(0, c(length(countries) * length(years_list), length(countries)),
                      dimnames = list(cy, countries))
country_year <- as.data.frame(country_year)
border_matrix <- country_year

# Read adjacency list file
file_conn <- file("adjacency_list.csv", "r")
lines <- readLines("adjacency_list.csv")

# Process each line
data <- lapply(lines, function(line) {
  parts <- strsplit(line, ",")[[1]]
  list(CountryYear = parts[1], Adjacencies = parts[-1])
})

# Convert list to dataframe
data_df <- do.call(rbind, lapply(data, function(x) data.frame(CountryYear = x$CountryYear, Adjacency = I(list(x$Adjacencies)))))
data_df$Country <- substr(data_df$CountryYear, 1, 3)
data_df$Year <- as.integer(substr(data_df$CountryYear, 4, 7))
data_df$YearGroup <- floor(data_df$Year / 2) * 2

# Aggregate the data
agg_adjacencies <- data_df %>%
  group_by(Country, YearGroup) %>%
  summarize(Adjacencies = toString(unique(unlist(Adjacency))))
agg_adjacencies$YearGroup = agg_adjacencies$YearGroup + 1.5

# Update the border_matrix based on adjacencies
for (i in 1:nrow(agg_adjacencies)) {
  row_id <- paste0(agg_adjacencies$Country[i], agg_adjacencies$YearGroup[i])
  adjacencies <- unlist(strsplit(agg_adjacencies$Adjacencies[i], ",\\s*"))
  
  # Mark 1 for each adjacency
  for (adj in adjacencies) {
    border_matrix[row_id, adj] = 1
  }
}

# Remove last column and row (redundant due to last comma in each line)
border_matrix <- border_matrix[, -ncol(border_matrix)]
border_matrix <- border_matrix[-nrow(border_matrix), ]

# Write the modified border matrix to a CSV file
write.csv(border_matrix, file = "nt2bynmat.csv", row.names = TRUE)

# Close the file connection
close(file_conn)
