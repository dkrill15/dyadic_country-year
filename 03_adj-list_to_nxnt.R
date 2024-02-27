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
years_list <- seq(from = START_YEAR * 10 + 5, to = END_YEAR * 10 + 5, by = 20)
cy <- expand.grid(countries, years_list)
cy <- apply(cy, 1, paste, collapse = "")
country_year <- array(0, c(length(countries) * length(years_list), length(countries)),
                      dimnames = list(cy, countries))
country_year <- as.data.frame(country_year)
border_matrix <- country_year

# Read adjacency list file
file_conn <- file("adjacency_list.csv", "r")

# Line-by-line data entry to create the border matrix
while (length(line <- readLines(file_conn, n = 1)) > 0) {
  if (grepl("5$", line)) {
    next
  }
  line_split <- unlist(strsplit(line, ","))
  country <- line_split[1]
  neighbor_list <- line_split[-1]
  border_matrix[country, neighbor_list] <- 1
}

# Remove last column (redundant due to last comma in each line)
border_matrix <- border_matrix[, -ncol(border_matrix)]

# Write the modified border matrix to a CSV file
write.csv(border_matrix, file = "ntbynmat.csv", row.names = TRUE)


# Close the file connection
close(file_conn)
