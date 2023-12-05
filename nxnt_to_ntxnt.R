setwd('~/kellogg/kellogg_r')

#read in matrix and fix rownames
border_matrix_n = read.csv(file = "ntbynmat.csv")
rownames(border_matrix_n) = border_matrix_n[,1]
border_matrix_n = border_matrix_n[-nrow(border_matrix_n), ]
border_matrix_n = border_matrix_n[,-1]

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
n = length(countries)
t = length(years_list)
country_year <- array(0, c(n*t, n*t),
                      dimnames = list(cy, cy))
country_year = as.data.frame(country_year)
border_matrix_nt = country_year
#### ####

#perform row weighting in ntxn matrix
for (i in 1:nrow(border_matrix_n)) {
  total_sum = sum(border_matrix_n[i, ])
  print(total_sum)
  if (total_sum > 1) {
    border_matrix_n[i, ] = lapply(border_matrix_n[i, ], function(x) x / total_sum)
  }
}

#expand matrix into nt by nt
for (i in 0:(t-1)){
  b = (i * n) + 1
  e = (i + 1) * n
  border_matrix_nt[b:e, b:e] = border_matrix_n[b:e,]
}

cat(paste0(nrow(border_matrix_n), '\n'), file="test_big_mat2.txt")
#write.csv(as.data.frame(border_matrix_nt), file = "test_big_mat.csv", row.names = FALSE, append=TRUE)

write.table(border_matrix_nt, file = "test_big_mat2.txt", 
            append = TRUE, sep = " ", row.names=FALSE, col.names=FALSE, quote=FALSE)

