library(haven)

# Constants
WORKING_DIR = "~/kellogg/kellogg_r/11.14"
NEIGHBORS_FILE = "missing_nabes.csv"
VDATA_FILE = "VData.rds"
START_YEAR = 1901
END_YEAR = 2019

# Read VDEM countries and border matrix
VData <- readRDS(file = VDATA_FILE)
countries <- sort(unique(VData$country_text_id))
border_matrix <- read_dta("border_mat_condensed.dta")

# Build country-year combinations
years_list <- seq(from = START_YEAR + 0.5, to = END_YEAR + 0.5, by = 2)
country_year_combinations <- expand.grid(countries, years_list)
country_year_combinations <- paste0(country_year_combinations$Var1, country_year_combinations$Var2)

# Initialize adjacency list
adj_list <- list()

# Convert matrix to adjacency list and write to CSV
file_conn <- file("adjacency_list.csv", "w")
writeLines(paste("Node,Connections"), con = file_conn)
for (i in 1:nrow(border_matrix)) {
  connected_nodes <- colnames(border_matrix)[which(border_matrix[i,] == 1)]
  row_name <- paste0(substr(country_year_combinations[i], 1, 7), "5")
  
  adj_list[[row_name]] <- connected_nodes  # Store adjacency list
  
  # Write to CSV
  writeLines(paste(c(row_name, paste(connected_nodes, collapse = ",")), collapse = ","), con = file_conn)
}

close(file_conn)
