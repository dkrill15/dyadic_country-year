import pycountry_convert as pc
import csv
import pandas as pd

# read iso3_to_region.csv file into pandas dataframe
def get_continents():
    continents = pd.read_csv('iso3_to_region.csv')
    continents = continents.set_index('iso3')
    r = list(continents['Region'].unique())
    c = list(continents['Continent'].unique())
    continents = continents.to_dict()
    return continents, r, c

iso3_to_region, regions, conts = get_continents()
colors = ['red', 'blue', 'green', 'yellow', 'orange', 'purple', 'pink', 'brown', 'black', 'grey', 'yellow', 'cyan', 'magenta', 'lime', 'teal', 'indigo', 'maroon', 'navy', 'olive', 'silver', 'aqua', 'fuchsia', 'lime', 'teal']
region2color = dict(zip(regions, colors))
continent2color = dict(zip(conts, colors[:5]))


def get_border_changes():
    def read_variable_length_csv(file_path):
        with open(file_path, newline='') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            return [row for row in reader]

    file_path = 'adjacency_list.csv'
    array = read_variable_length_csv(file_path)
    max_len = max(len(row) for row in array)
    # Pad shorter rows with None (NaN in DataFrame)
    padded_array = [row + [None]*(max_len - len(row)) for row in array]
    # Convert to DataFrame
    df = pd.DataFrame(padded_array)

    # add column year that is the last 5 characters of the first column
    df['year'] = df[0].str[-4:]

    # # make 'year' the third column
    df = df[[0, 'year', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]]

    # # make the first column only its first three characters
    df[0] = df[0].str[:3]

    # # change all NaN to 0
    df = df.fillna(0)

    full_df = df.copy()

    df = df.drop_duplicates(
        subset=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], keep='first')

    df = df.groupby(0, axis=0).filter(lambda x: len(x) > 1)

    return df, full_df



def country_to_continent(country_alpha3, region = 1):
    if region:
        return region2color[iso3_to_region['Region'][country_alpha3]]

    return continent2color[iso3_to_region['Continent'][country_alpha3]]


