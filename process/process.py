import json
import re
import os
import collections

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

def get_citation_hrefs(body_html):
    soup = BeautifulSoup(body_html, 'lxml')
    hrefs = list()
    for elem in soup.find_all('a', attrs={'class': 'citation'}):
        hrefs.append(elem.get('href'))
    return hrefs

def get_cited_dois(body_html):
    """Return a set of cited DOIs from a `body_html` string"""
    citation_hrefs = get_citation_hrefs(body_html)
    dois = [re.search(doi_pattern, href) for href in citation_hrefs]
    dois = filter(None, dois)
    dois = [doi.group() for doi in dois]
    return dois

doi_pattern = re.compile(r'10\.\d{4,9}/[-._;()/:A-Z0-9]+', re.IGNORECASE)

def is_doi(citation_key):
    """
    Returns whether a citation_key is a DOI
    `doi_pattern` is from:
    http://blog.crossref.org/2015/08/doi-regular-expressions.html
    """
    match = re.fullmatch(doi_pattern, citation_key)
    return bool(match)

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

    document_df = key_to_df['documents']
    combined_html = document_df.intro_html + document_df.body_html
    document_df['word_count'] = combined_html.map(word_count)
    document_df['character_count'] = combined_html.map(character_count)
    return key_to_df

def write_key_to_df(key_to_df, directory='table'):
    drop_keys = {'intro_html', 'intro_md', 'body_html', 'body_md'}
    for key, df in key_to_df.items():
        df = df.drop(drop_keys & set(df.columns), axis='columns')
        path = os.path.join(directory, key + '.tsv')
        df.to_csv(path, sep='\t', index=False, float_format='%.0f')

def summarize_content_df(df, prepend):
    summary = pandas.Series()
    summary[prepend + '_count'] = len(df)
    summary[prepend + '_word_count'] = df.word_count.sum()
    summary[prepend + '_character_count'] = df.character_count.sum()
    return summary

def get_citation_counts(texts):
    doi_counter = collections.Counter()
    for text in texts:
        doi_citations = get_cited_dois(text)
        doi_counter.update(doi_citations)
    return doi_counter

def summarize_projects(key_to_df):
    """Create summary stats for each project"""
    dfs = list()

    df = key_to_df['profiles'].groupby('project').apply(lambda df: pandas.Series({'contributors': len(df)}))
    dfs.append(df)

    project_to_texts = dict()
    for key in 'comments', 'notes', 'documents':
        groups = key_to_df[key].groupby('project')
        df = groups.apply(summarize_content_df, prepend=key[:-1])
        dfs.append(df)
        for project, df in groups:
            for col in 'body_html', 'intro_html':
                project_to_texts.setdefault(project, []).extend(df.get(col, []))

    rows = list()
    for project, texts in project_to_texts.items():
        for doi, count in get_citation_counts(texts).items():
            rows.append((project, doi, count))
    citation_df = pandas.DataFrame(rows, columns=['project', 'doi', 'citation_count'])
    citation_df.sort_values(['project', 'citation_count', 'doi'], ascending=[1, 0, 1], inplace=True)

    df = citation_df.groupby('project').apply(lambda df: pandas.Series({'cited_dois': len(df)}))
    dfs.append(df)

    summary_df = pandas.concat(dfs, axis='columns').fillna(0).astype(int)
    summary_df.index.name = 'project'
    summary_df.reset_index(inplace=True)

    return summary_df, citation_df


if __name__ == '__main__':
    json_dir = os.path.join('..', 'export', 'json')
    project_to_export = get_project_to_export(json_dir)
    key_to_df = get_key_to_df(project_to_export)
    write_key_to_df(key_to_df)
    summary_df, citation_df = summarize_projects(key_to_df)

    for name, df in ('summaries', summary_df), ('citations', citation_df):
        path = os.path.join('table', '{}.tsv'.format(name))
        df.to_csv(path, sep='\t', index=False)
