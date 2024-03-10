import geopandas as gpd
import matplotlib.pyplot as plt
import pandas as pd


# network view with node loations determined by centoid 
# look at html file for output
# make sure there is zoom functionality

def plot_country_highlighted(iso3_code):
    # Ensure the country code is in uppercase
    iso3_code = iso3_code.upper()

    # Check if the country code exists in the dataset
    valid_country = iso3_code in world['iso_a3'].values
    if not valid_country:
        print(f"Country code {iso3_code} not found.")
        return
        
    # Plot the world map
    else:
        base = world.plot(color='lightgrey')
        world[world['iso_a3'] == iso3_code].plot(ax=base, color='red')
        world.boundary.plot(ax=base, color='black')
    # Find the country's geometry
    country = world[world['iso_a3'] == iso3_code]
    neighbors = world[world['iso_a3'].isin(df[df[iso3_code] == 1].index)]

    title = str(len(neighbors)) + " Neighbors of " + \
        iso3_code if valid_country else "Invalid country code: " + iso3_code
    plt.title(title)

    minx, miny, maxx, maxy = 99999999, 9999999, -99999999, -9999999
  
    for i, n in neighbors.bounds.iterrows():
        minx = min(n['minx'] * .9, minx)
        miny = min(n['miny']* .9, miny)
        maxx = max(n['maxx']*1.1, maxx)
        maxy = max(n['maxy']*1.1, maxy)

    # Plot world map
    world.plot(ax=base, color='lightgrey', edgecolor='black')
    neighbors.plot(
        ax=base, color='blue')

    # Highlight the selected country
    country.plot(ax=base, color='green', edgecolor='black')

    # Set plot limits to focus on the country
    print(iso3_code, minx, miny, maxx, maxy)
    base.set_xlim(minx, maxx)
    base.set_ylim(miny, maxy)
    # center plot on country

    plt.gcf().set_size_inches(10, 10)
    plt.show()

# Example usage
year_selected = int(input("Enter the year: "))
iso3_code = input("Enter the country code: ")
df = pd.read_stata('border_mat_condensed.dta')
# print row names
year_offset = year_selected - 1901
df = df.iloc[year_offset*183:year_offset*183+183, :]

# set index to match columns
df.set_index(df.columns, inplace=True)
# load world map with gpd

world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))

# get difference of df.columns and world['iso_a3']
print("In research dataset but not in map display:")
print(df.columns.difference(world['iso_a3']))

# get difference of world['iso_a3'] and df.columns
print("In research dataset but not in map display:")
print(set(world['iso_a3'].tolist()).difference(df.columns.tolist()))

# for iso3_code in df.columns:
plot_country_highlighted(iso3_code)
