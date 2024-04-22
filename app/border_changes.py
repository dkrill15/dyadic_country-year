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

def read_adj_list():
    def read_variable_length_csv(file_path):
        with open(file_path, newline='') as csvfile:
            reader = csv.reader(csvfile, delimiter=',', quotechar='"')
            return [row for row in reader]
    file_path = 'adjacency_list.csv'
    array = read_variable_length_csv(file_path)
    max_len = max(len(row) for row in array)
    padded_array = [row + [None]*(max_len - len(row)) for row in array]
    df = pd.DataFrame(padded_array)
    df['year'] = df[0].apply(lambda x: x[-4:])    
    df[0] = df[0].apply(lambda x: x[:3])
    df = df[[0, 'year'] + list(range(1, 18))]
    df = df.fillna(0).replace("", 0)
    df = df.iloc[1:]
    return df

def get_border_changes():
    df = read_adj_list()
    full_df = df.copy()
    new_df = df.drop_duplicates(
        subset=[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17], keep='first')
    new_df = new_df.groupby(0).filter(lambda x: len(
        x) > 1 or (len(x) == 1 and int(x['year'].values[0]) > 1902))
    return new_df, full_df

def country_to_continent(country_alpha3, region = 1):
    if region:
        return region2color[iso3_to_region['Region'][country_alpha3]]
    return continent2color[iso3_to_region['Continent'][country_alpha3]]

def compile_changelog():
    df_changes, full_df = get_border_changes()
    change_desc = ""
    for year in range(1902, 2020):
        old_neighbors = full_df[full_df['year'] == str(year - 1)]
        changes = df_changes[df_changes['year'] == str(year)]
        change_desc += f"{year}\n"
        if not changes.empty:
            for i, country in changes.iterrows():
                ck = old_neighbors[old_neighbors[0] == country[0]].iloc[:, 2:].values[0]
                old = set(ck) - {'', 0}
                cur_neighbors = set(country[2:]) - {'', 0}
                added = list(cur_neighbors.difference(old))
                lost = list(old.difference(cur_neighbors))
                if len(old) == 0:
                    change_desc += f"\t{country[0]} enters the map\n\n"
                elif len(cur_neighbors) == 0:
                    change_desc += f"\t{country[0]} leaves the map\n\n"
                else:
                    change_desc += f"\t{country[0]} changed neighbors\n\t\tAdded: {', '.join(added)}\n\t\tLost: {', '.join(lost)}\n\n"
        else:
            change_desc += "\tNo changes in neighbors\n\n"
    else:
        change_desc += "\tNo previous year to compare to\n\n"

    return change_desc
