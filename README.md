# Generate Dyadic Country Matrices

Use these R scripts to build 4 different representations of country-by-country contiguity and centroid distance. 

## Running the Scripts

In all scripts, make sure to change working directory variables.

### 01: build_weight_matrices

This file makes calls to the CShapes package and calculates 1) distance between centroids of two countries and 2) whether those countries are contiguous, and it averages these values over 2 years to produce a metric for each for every 2 years. A preconfigured island_dict specifies user-supplied contiguous countries for all islands. Each year takes ~5 minutes to run. 

### 02-04

These files transform the output of **01** to an adjacency list csv (for editing in spreadsheet software), then to a country-year-by-country matrix (for uploading to a remote machine), then to a country-year-by-country-year matrix (unpacks the previous matrix once uploaded to remote machine).

## App

The `app` folder contains a Dash app that displays the output of script 02. Install the necessary requirements from `requirements.txt` and run the app locally to view a force-directed network of countries for all the years studied. The app is deployed [here](https://dyadic-country-year.onrender.com)
![Screenshot 2024-04-23 at 12 45 04 AM](https://github.com/dkrill15/dyadic_country-year/assets/71748033/356d5477-dd74-4c7a-b22d-3645cd8d3793)


## Data

### missing_nabes.csv 
Contains island countries that informs the creation of island_dict in **01**.

### Not included in repo
Please obtain supplementary shapefiles for South Sudan, Timor Leste, Hong Kong, and Montenegro, as CShapes does not contain data for these countries.
