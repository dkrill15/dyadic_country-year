#packages
library(cshapes)
library(countrycode)
library(geosphere)
library(od)
library(spdep)
library(sf)
library(rgeos)
library(tidyverse)

#constants
WORKING_DIR = "~/kellogg/kellogg_r"
NEIGHBORS_FILE = "missing_nabes.csv"
VDATA_FILE = "VData.rds"
START_YEAR = 1901
END_YEAR = 2019
MAX_DATE = 2020 # do not change - indicates first unavailable year of cshapes data

get_island_dict <- function () {
  # Build a dictionary of island neighbors
  islands <- read.csv(NEIGHBORS_FILE, stringsAsFactors = FALSE)
  islands <- islands[, !(names(islands) %in% c("X", "year"))]
  
  # Create an empty list for the island dictionary
  island_dict <- list()
  
  # Loop over rows and populate the island dictionary
  for (i in 1:nrow(islands)) {
    country <- islands[i, "cname"]
    neighbors <- unlist(strsplit(gsub('[()c"",]', '', islands[i, "nabeslist"]), "\\s+"))
    
    island_dict[[country]] <- c(island_dict[[country]], neighbors)
    
    for (n in neighbors) {
      if (!(n %in% islands$cname)) {
        island_dict[[n]] <- c(island_dict[[n]], country)
      }
    }
  }
  
  return (island_dict)
}

main_workflow <- function () {
  setwd(WORKING_DIR)
  
  # Dictionary for manual translation
  extra_code_dict <- c(
    "265" = 'DDR', "260" = "DDR", "997" = 'HKG', "665" = 'PSB', "6631" = 'PSE',
    "6511" = 'PSG', "521" = 'SML', "5200" = 'SML', "345" = 'SRB', 
    "817" = 'VDR', "347" = 'XKX', "678" = 'YMD', "511" = 'ZZB'
  )
  
  # Add countries in VData but not in CShapes
  south_sudan = st_read('ssd_admbnda_imwg_nbs_20221219_SHP/ssd_admbnda_adm0_imwg_nbs_20221219.shp')$geometry
  timor_leste = st_read('tls_adm_who_ocha_20200911_shp/tls_admbnda_adm0_who_ocha_20200911.shp')$geometry[1]
  montenegro = st_read('geoBoundaries-MNE-ADM0-all/geoBoundaries-MNE-ADM0.shp')$geometry
  hong_kong = st_read('hongkong_boundaries/HKG_adm0.shp')$geometry
  new_countries = data.frame('cowcode' = c('MNE', 'SSD', 'TLS', 'HKG'), 
                             'geometry' = c(montenegro, south_sudan, timor_leste, hong_kong),
                             'old_code' = c(0,0,0,0))
  
  island_dict <- get_island_dict()
  
  # Read the VData RDS file
  VData <- readr::read_rds(file = VDATA_FILE)
  countries <- sort(unique(VData$country_text_id))
  
  # Generate country-year names
  years_list <- seq(from = START_YEAR * 10 + 5, to = END_YEAR * 10 + 5, by = 2)
  cy <- as.vector(t(sapply(countries, function(c) paste0(c, years_list))))
  
  # Create country-year x country-year matrix
  num_countries <- length(countries)
  num_years <- length(years_list)
  cy_matrix <- matrix(0, nrow = num_countries * num_years, ncol = num_countries,
                      dimnames = list(cy, countries))
  country_year <- as.data.frame(cy_matrix)
  
  # Initialize weights matrices
  border_mat <- country_year
  dist_mat <- country_year
  
  years_list_loop = seq(from = START_YEAR, to = END_YEAR, by = 2)
  
  get_cshapes_data <- function(cur_year) {
    cshapes_data = cshp(date = as.Date(cur_year), useGW = FALSE, dependencies = TRUE)
    cshapes_data$old_code = cshapes_data$cowcode
    cshapes_data$cowcode = countrycode(cshapes_data$cowcode, "cown", "iso3c", warn = TRUE, nomatch = NA)
    
    cshapes_data$cowcode = ifelse(is.na(cshapes_data$cowcode), extra_code_dict[as.character(cshapes_data$old_code)], 
                                  cshapes_data$cowcode)
    cshapes_data = bind_rows(cshapes_data, new_countries)
    cshapes_data = cshapes_data[cshapes_data$cowcode %in% countries,]
    cshapes_data = cshapes_data[!duplicated(cshapes_data$cowcode), ] 
    cshapes_data = cshapes_data[,c("cowcode", "geometry", "old_code")]
    cshapes_data = cshapes_data[!is.na(cshapes_data$cowcode),]
    
    return (cshapes_data)
  }
  
  for (year in years_list_loop) {
    print(paste0("Retrieving CShapes data for: ", year))
    cur_year = paste(year, "-01-01", sep="")
    next_year = paste(year+1, "-01-01", sep="")
    
    # Retrieve CShapes data
    cshapes_data <- get_cshapes_data(cur_year)
    cshapes_data_next <- if (next_year < MAX_DATE) {
      get_cshapes_data(next_year)
    } else {
      cshapes_data
    }
    
    # Calculate centroids for distance calculation later
    sf_use_s2(FALSE)
    cshapes_data$centroids = st_centroid(cshapes_data$geometry)
    cshapes_data_next$centroids = st_centroid(cshapes_data_next$geometry)
    sf_use_s2(TRUE)
    
    print(paste0("calculating distances and borders for: ", year))
    
    # Ensure that only countries included in this year are included
    lcountries = sort(cshapes_data$cowcode)
    lcountries = intersect(lcountries, cshapes_data_next$cowcode)
    
    # Keep duplicate list to halve loop time
    countries_left = lcountries
    
    # year is the average of these two years (current year + .5) - represented as YYYY5
    year = year * 10 + 5
    
    pb <- txtProgressBar(min = 0,     
                         max = length(lcountries) * length(countries) / 2, 
                         style = 3,   
                         width = 50,   
                         char = "=")   
    prog_val = 0
    
    # Build country x country matrix for current year
    for (country in lcountries){
      country_year_name = paste0(country, year)
      for (country2 in countries_left){
        country2_year_name = paste0(country2, year)
        
        #### POPULATE MATRICES ####
        # Calculate border - averaged over 2 years
        touch = country %in% island_dict[[country2]] | (gTouches(as(cshapes_data[cshapes_data$cowcode==country,], Class="Spatial"), 
                                                                 as(cshapes_data[cshapes_data$cowcode==country2,], Class="Spatial")))
        touch2 = country %in% island_dict[[country2]] | gTouches(as(cshapes_data_next[cshapes_data_next$cowcode==country,], Class="Spatial"), 
                                                                 as(cshapes_data_next[cshapes_data_next$cowcode==country2,], Class="Spatial"))
        border_mat[country2_year_name, country] = (touch + touch2) / 2
        
        # Calculate distance - averaged over 2 years
        dist_mat[country2_year_name, country] =
          (distm(sfc_point_to_matrix(cshapes_data$centroids[cshapes_data$cowcode==country]), sfc_point_to_matrix(cshapes_data$centroids[cshapes_data$cowcode==country2]), fun = distHaversine) +
             distm(sfc_point_to_matrix(cshapes_data_next$centroids[cshapes_data_next$cowcode==country]), sfc_point_to_matrix(cshapes_data_next$centroids[cshapes_data_next$cowcode==country2]), fun = distHaversine) / 2)
      }
      # Update countries_left (so less calls are made)
      countries_left <- countries_left[! countries_left %in% country]
      
      prog_val <- prog_val + length(countries_left)
      setTxtProgressBar(pb, prog_val)
    }
    close(pb)
  }
  
  for (i in 0:(nrow(border_mat) / ncol(border_mat))){
    # Start and endpoints for each year x year block
    start = i*ncol(border_mat) + 1
    end = (i+1) * ncol(border_mat)
    
    # Compute transposes of border matrix
    trp = t(border_mat[start:end,])
    border_mat[start:end,] = border_mat[start:end,]+trp
    
    # Compute and add transposes of distance matrix
    trp = t(dist_mat[start:end,])
    dist_mat[start:end,] = dist_mat[start:end,] + trp
  }

  # Export to stata-readable file
  require(foreign)
  write.dta(as.data.frame(dist_mat), paste("dist_mat_condensed",".dta", sep=""))
  write.dta(as.data.frame(border_mat), paste("border_mat_condensed",".dta", sep=""))
}

main_workflow()
