#############
#Final Version
#############

install.packages("cshapes", dependencies = TRUE)
library(cshapes)
library(countrycode)
library(geosphere)
library(od)
library(spdep)
library(sf)
library(rgeos)
library(tidyverse)

#set working directory
setwd('~/kellogg/kellogg_r')


### Manual Preprocessing ###
#make dictionary for manual translation
extra_code_dict = c("265" = 'DDR', "260" = "DDR", "997" = 'HKG', "665" = 'PSB', "6631" = 'PSE',
                    "6511" = 'PSG', "521" = 'SML', "5200" = 'SML', "345" = 'SRB', 
                    "817" = 'VDR', "347" = 'XKX', "678" = 'YMD', "511" = 'ZZB')

#add extra countries (four)
south_sudan = st_read('ssd_admbnda_imwg_nbs_20221219_SHP/ssd_admbnda_adm0_imwg_nbs_20221219.shp')$geometry
timor_leste = st_read('tls_adm_who_ocha_20200911_shp/tls_admbnda_adm0_who_ocha_20200911.shp')$geometry[1]
montenegro = st_read('geoBoundaries-MNE-ADM0-all/geoBoundaries-MNE-ADM0.shp')$geometry
hong_kong = st_read('hongkong_boundaries/HKG_adm0.shp')$geometry

#build list to add on to cshapes_data
new_countries = data.frame('cowcode' = c('MNE', 'SSD', 'TLS', 'HKG'), 
                           'geometry' = c(montenegro, south_sudan, timor_leste, hong_kong),
                           'old_code' = c(0,0,0,0))

#build dictionary of island neighbors
islands = read.csv("missing_nabes.csv")
islands[c("X", "year")] = NULL
island_dict = list()

for(i in 1:nrow(islands)) {       # for-loop over rows
  country = islands[i, "cname"]
  neighbors = strsplit(gsub('[()c"",]', '', islands[i, "nabeslist"]), "\\s+")[[1]]
  
  #add neighbors to island_dict in country's entry and in their own if it doesn't exist
  for (n in neighbors) {
    island_dict[[country]] = c(island_dict[[country]], n)
    if (!(n %in% islands$cname)) {
      island_dict[[n]] = c(island_dict[[n]], country)
    }
  }
}
### ###

### Build Empty Matrix ###
#read in VDEM countries
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

#set up weights matrices
border_mat = country_year
dist_mat = country_year
### ###

#build weights matrices (neighbors, distance) - takes ~5 hours to run
years_list_loop = seq(from = 2019, to = 2019, by = 2)
MAX_DATE = 2020
for (year in years_list_loop) {
  print(paste0("getting cshapes data for: ", year))
  cur_year = paste(year, "-01-01", sep="")
  next_year = paste(year+1, "-01-01", sep="")
  
  #get data from current year
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
  
  #get data from next year
  if (next_year < MAX_DATE) {
    cshapes_data_next = cshp(date = as.Date(next_year), useGW = FALSE, dependencies = TRUE)
    cshapes_data_next$old_code = cshapes_data_next$cowcode
    cshapes_data_next$cowcode = countrycode(cshapes_data_next$cowcode, "cown", "iso3c", warn = TRUE, nomatch = NA)
    
    cshapes_data_next$cowcode = ifelse(is.na(cshapes_data_next$cowcode), extra_code_dict[as.character(cshapes_data_next$old_code)], 
                                       cshapes_data_next$cowcode)
    cshapes_data_next = bind_rows(cshapes_data_next, new_countries)
    cshapes_data_next = cshapes_data_next[cshapes_data_next$cowcode %in% countries,]
    cshapes_data_next = cshapes_data_next[!duplicated(cshapes_data_next$cowcode), ]
    cshapes_data_next = cshapes_data_next[,c("cowcode", "geometry", "old_code")]
    cshapes_data_next = cshapes_data_next[!is.na(cshapes_data_next$cowcode),]
  }
  else {
    cshapes_data_next = cshapes_data
  }
  
  #calculate centroids for distance calculation later
  sf_use_s2(FALSE)
  cshapes_data$centroids = st_centroid(cshapes_data$geometry)
  cshapes_data_next$centroids = st_centroid(cshapes_data_next$geometry)
  sf_use_s2(TRUE)
  
  print(paste0("calculating distances and borders for: ", year))
  
  #ensure that only countries included in this year are included
  lcountries = sort(cshapes_data$cowcode)
  lcountries = intersect(lcountries, cshapes_data_next$cowcode)
  
  #keep duplicate list to halve loop time
  countries_left = lcountries
  
  #year is the average of these two years (current year + .5) - represented as YYYY5
  year = year * 10 + 5
  
  #build country x country matrix for current year
  for (country in lcountries){
    country_year_name = paste0(country, year)
    for (country2 in countries_left){
      country2_year_name = paste0(country2, year)
      
      #### POPULATE MATRICES ####
      #calculate border - averaged over 2 years
      touch = country %in% island_dict[[country2]] | (gTouches(as(cshapes_data[cshapes_data$cowcode==country,], Class="Spatial"), 
                                                               as(cshapes_data[cshapes_data$cowcode==country2,], Class="Spatial")))
      touch2 = country %in% island_dict[[country2]] | gTouches(as(cshapes_data_next[cshapes_data_next$cowcode==country,], Class="Spatial"), 
                                                               as(cshapes_data_next[cshapes_data_next$cowcode==country2,], Class="Spatial"))
      border_mat[country2_year_name, country] = (touch + touch2) / 2
      
      #calculate distance - averaged over 2 years
      dist_mat[country2_year_name, country] =
        (distm(sfc_point_to_matrix(cshapes_data$centroids[cshapes_data$cowcode==country]), sfc_point_to_matrix(cshapes_data$centroids[cshapes_data$cowcode==country2]), fun = distHaversine) +
           distm(sfc_point_to_matrix(cshapes_data_next$centroids[cshapes_data_next$cowcode==country]), sfc_point_to_matrix(cshapes_data_next$centroids[cshapes_data_next$cowcode==country2]), fun = distHaversine) / 2)
      
      print(paste0("Matched", country2, "to", country))
      
    }
    #update countries_left (so less calls are made)
    countries_left <- countries_left[! countries_left %in% country]
  }
}


for (i in 0:(nrow(border_mat) / ncol(border_mat))){
  #start and endpoints for each year x year block
  start = i*ncol(border_mat) + 1
  end = (i+1) * ncol(border_mat)
  
  #compute transposes of border matrix
  trp = t(border_mat[start:end,])
  border_mat[start:end,] = border_mat[start:end,]+trp
  
  #compute and add transposes of distance matrix
  trp = t(dist_mat[start:end,])
  dist_mat[start:end,] = dist_mat[start:end,] + trp
}


#export to stata-readable file
require(foreign)
write.dta(as.data.frame(dist_mat), paste("dist_mat_condensed",".dta", sep=""))
write.dta(as.data.frame(border_mat), paste("border_mat_condensed",".dta", sep=""))


#POTENTIAL EXTENSIONS
#do colonizer relationship 1 to colony; 1/n to colonizer
#distance between capitals
#make an r package, 
