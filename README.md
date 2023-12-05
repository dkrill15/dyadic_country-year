# Generate Dyadic Country Matrices

Use these R scripts to build 4 different representations of country-by-country contiguity and centroid distance. 

# TODO:
add links to extra shapefiles

# Scripts

StackEdit stores your files in your browser, which means all your files are automatically saved locally and are accessible **offline!**

### 01: build_weight_matrices

This file makes calls to the CShapes package and calculates 1) distance between centroids of two countries and 2) whether those countries are contiguous, and it averages these values over 2 years to produce a metric for each for every 2 years. A preconfigured island_dict specifies user-supplied contiguous countries for all islands. Each year takes ~5 minutes to run. 

### 02-04

These files transform the output of **01** to an adjacency list csv (for editing in spreadsheet software), then to a country-year-by-country matrix (for uploading to a remote machine), then to a country-year-by-country-year matrix (unpacks the previous matrix once uploaded to remote machine).

## Data

### missing_nabes.csv 
Contains island countries that informs the creation of island_dict in **01**.

### not included in repo

list files not uploaded here
