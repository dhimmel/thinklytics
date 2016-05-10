import json
import re
import os

import pandas
from bs4 import BeautifulSoup

def extract_words(body_html):
    """
    Extract the visible words in a chunk of HTML.
    """
    soup = BeautifulSoup(body_html, 'lxml')
    texts = soup.findAll(text=True)
    text = ' '.join(texts)
    words = re.findall(r'\w+', text)
    return words

def word_count(body_html):
    """
    Count the visible words in a chunk of HTML.
    """
    return len(extract_words(body_html))

def character_count(body_html):
    """
    Count the visible characters in a chunk of HTML.
    """
    soup = BeautifulSoup(body_html, 'lxml')
    character_count = sum(len(x) for x in soup.findAll(text=True))
    return character_count

def df_from_key(project_to_export, key):
    dfs = list()
    for project, export in project_to_export.items():
        df = pandas.DataFrame(export[key])
        df['project'] = project
        dfs.append(df)
    return pandas.concat(dfs)

def get_project_to_export(directory):
    """
    Read the JSON files in the directory
    """
    project_to_export = dict()
    for filename in os.listdir(directory):
        if not filename.endswith('.json'):
            continue
        path = os.path.join(directory, filename)
        with open(path) as read_file:
            export = json.load(read_file)
        project = filename[:-5]
        project_to_export[project] = export
    return project_to_export

def get_key_to_df(project_to_export):
    key_to_df = dict()
    for key in 'notes', 'comments', 'threads', 'profiles', 'documents':
        df = df_from_key(project_to_export, key)
        df.sort_values(['project', key[:-1] + '_id'], inplace=True)
        key_to_df[key] = df

    for key in 'notes', 'comments':
        df = key_to_df[key]
        df['word_count'] = df.body_html.map(word_count)
        df['character_count'] = df.body_html.map(character_count)
        df.drop(['body_html', 'body_md'], axis='columns', inplace=True)

    document_df = key_to_df['documents']
    combined_html = document_df.intro_html + document_df.body_html
    document_df['word_count'] = combined_html.map(word_count)
    document_df['character_count'] = combined_html.map(character_count)
    document_df.drop(['intro_html', 'intro_md', 'body_html', 'body_md'], axis='columns', inplace=True)
    return key_to_df

def write_key_to_df(key_to_df, directory='table'):
    for key, df in key_to_df.items():
        path = os.path.join(directory, key + '.tsv')
        df.to_csv(path, sep='\t', index=False, float_format='%.0f')

if __name__ == '__main__':
    json_dir = os.path.join('..', 'export', 'json')
    project_to_export = get_project_to_export(json_dir)
    key_to_df = get_key_to_df(project_to_export)
    write_key_to_df(key_to_df)
