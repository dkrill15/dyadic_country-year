# Constants
WORKING_DIR <- "~/kellogg/kellogg_r/11.14"
NEIGHBORS_FILE <- "missing_nabes.csv"
VDATA_FILE <- "VData.rds"
START_YEAR <- 1901
END_YEAR <- 2019

setwd(WORKING_DIR)

# Read in the matrix and adjust row names
border_matrix_n <- read.csv(file = "ntbynmat.csv")
rownames(border_matrix_n) <- border_matrix_n[, 1]
border_matrix_n <- border_matrix_n[-nrow(border_matrix_n), -1]

# Build matrix
VData <- readRDS(file = "VData.rds")
countries <- sort(unique(VData$country_text_id))

# Get country-year names
years_list <- seq(from = START_YEAR * 10 + 5, to = END_YEAR * 10 + 5, by = 20)
cy <- expand.grid(countries, years_list)
cy <- apply(cy, 1, paste, collapse = "")
n <- length(countries)
t <- length(years_list)
country_year <- array(0, c(n * t, n * t), dimnames = list(cy, cy))
country_year <- as.data.frame(country_year)
border_matrix_nt <- country_year

# Perform row weighting in ntxn matrix
for (i in 1:nrow(border_matrix_n)) {
  total_sum <- sum(border_matrix_n[i, ])
  if (total_sum > 1) {
    border_matrix_n[i, ] <- border_matrix_n[i, ] / total_sum
  }
}

# Expand matrix into nt by nt
for (i in 0:(t - 1)) {
  b <- (i * n) + 1
  e <- (i + 1) * n
  border_matrix_nt[b:e, b:e] <- border_matrix_n[b:e, ]
}

cat(nrow(border_matrix_n), '\n', file = "ntxnt.txt")

write.table(border_matrix_nt, file = "ntxnt.txt",
            append = TRUE, sep = " ", row.names = FALSE, col.names = FALSE, quote = FALSE)


