import dash
import visdcc
import pandas as pd
from dash import dcc
from dash import html
from dash.dependencies import Input, Output
from app.border_changes import get_border_changes, country_to_continent, compile_changelog

external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css']
app = dash.Dash(__name__, external_stylesheets=external_stylesheets)

with open('adjacency_list.csv', 'r') as f:
    headers = f.readline()
    adj_list = f.readlines()
dist_df = pd.read_stata('dist_mat_condensed.dta')

fixed_nodes = {
    'USA': {'x': -1700, 'y': 0},
    'FRA': {'x': 0, 'y': -50},
    # 'CHN': {'x': 1500, 'y': 180},
    # 'RUS': {'x': 1000, 'y': -90},
    'BRA': {'x': -700, 'y': 1500},
    'ZAF': {'x': 300, 'y': 2000},
    'AUS': {'x': 1650, 'y': 2000},
    'MLI': {'x': -200, 'y': 900},
    'GRC': {'x': 280, 'y': 375},
    'SAU': {'x': 675, 'y': 775},
    'SOM': {'x': 620, 'y': 950},
    'EGY': {'x': 400, 'y': 650},
    'TWN': {'x': 1650, 'y': 600},
}

df_changes, full_df = get_border_changes()

app.layout = html.Div([
    visdcc.Network(id='network', options=dict(height='800px', width='100%')),
    dcc.Slider(
        id='year-slider',
        min=1901,
        max=2019,
        value=1902,
        marks={str(year): str(year) for year in range(1901, 2020) if year % 5 == 0 or year == 1901 or year == 2019},
    ), 
    dcc.Checklist(['Distance Labels On'], [
                  'Distance Labels On'], id='check-dist-labels'),
    html.H2(id='slider-output-container'),
    html.Button("Download Neighbors", id='download-button'),
    dcc.Download(id='download-text'),
    html.P(id='differences'),
])

app.title = 'Country Network'

def text_to_dash_paragraph_with_line_breaks(text):
    lines = text.split('\n')
    components = [lines[0]] if lines else []
    for line in lines[1:]:
        components.append(html.Br()) 
        components.append(line)      
    paragraph = html.P(components)
    return paragraph

@app.callback(
    Output('network', 'data'),
    Output('slider-output-container', 'children'),
    Output('differences', 'children'),
    [Input('year-slider', 'value'),
     Input('check-dist-labels', 'value')]
)
def update_data(year, dist_labels):
    edges = []
    nodes = []
    visited = []
    y = year - 1901
    for i, line in enumerate(adj_list[y*183: (y+1)*183]):
        line = line.strip().split(',')
        source = line[0][:3]
        targets = line[1:]
        if targets[0] != '':
            for t in targets:
                if t not in visited:
                    edges.append(
                        {
                            'from': source, 
                            'to': t, 
                            'length': dist_df.loc[y*183+i, t]/5000,
                            'smooth' : False
                            })
                    if dist_labels:
                        edges[-1]['label'] = str(int(dist_df.loc[y*183+i, t])) + ' km'
            if source in fixed_nodes:
                xg = fixed_nodes[source]['x']
                yg = fixed_nodes[source]['y']
                nodes.append({'id': source, 'label': source, 'shape': "dot", 'size':15, 'x': xg, 'y': yg, 'fixed' : {'x': True, 'y': True}, 'color': country_to_continent(source)})
            else:
                nodes.append({'id': source, 'label': source, 'shape': "dot", 'size': 7, 'fixed': False, 'color': country_to_continent(source)})
            visited.append(source)
    change_desc = ""
    if year > 1901:
        old_neighbors = full_df[full_df['year'] == str(year - 1)]
        changes = df_changes[df_changes['year'] == str(year)]
        if not changes.empty:
            for i, country in changes.iterrows():
                ck = old_neighbors[old_neighbors[0] == country[0]].iloc[:, 2:].values[0]
                old = set(ck) - {'', 0}
                cur_neighbors = set(country[2:]) - {'', 0}
                added = list(cur_neighbors.difference(old))
                lost = list(old.difference(cur_neighbors))
                if len(old) == 0:
                    change_desc += f"{country[0]} enters the map\n\n"
                elif len(cur_neighbors) == 0:
                    change_desc += f"{country[0]} leaves the map\n\n"
                else:
                    change_desc += f"{country[0]} changed neighbors\nAdded: {', '.join(added)}\nLost: {', '.join(lost)}\n\n"
        else:
            change_desc = "No changes in neighbors"
    else:
        change_desc = "No previous year to compare to"
    
    return {'nodes': nodes, 'edges': edges}, f'Year: {year}', text_to_dash_paragraph_with_line_breaks(change_desc)


@app.callback(
    Output("download-text", "data"),
    Input("download-button", "n_clicks"),
    prevent_initial_call=True,
)
def download_neighbors():
    return dict(content=compile_changelog(), filename="border_changes.txt")

if __name__ == '__main__':
    app.run_server(debug=True, port=8051)