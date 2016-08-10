import argparse
import json
import datetime
import os
import time

import requests
from bs4 import BeautifulSoup as bfs

headers = {
    'referer': 'https://thinklab.com',
}

project_listing_urls = [
    'https://thinklab.com/proposals',
    'https://thinklab.com/projects',
]

def retrieve_project_urls(url, css_sel = 'a.list-proj-name'):
    """
    Retrieve the list of url for projects or proposals,
    based on the url fof the page that lists them
    """
    r = requests.get(url)
    soup = bfs(r.text, 'lxml')
    link_tags = soup.select(css_sel)
    return [x.attrs['href'][3:] for x in link_tags]

def base_payload(session):
    """Create a base payload with the CSRF token for the session"""
    payload = {
        'csrfmiddlewaretoken': session.cookies['csrftoken'],
    }
    return payload

def start_session(username, password):
    """Initiate a Thinklab requests session"""
    session = requests.Session()
    login_url = 'https://thinklab.com/login'
    session.get(login_url)
    payload = base_payload(session)
    payload['email'] = username
    payload['password'] = password
    session.post(login_url, data=payload, headers=headers)
    return session

def retrieve_project_export(project, session):
    """
    Retrieve a JSON-formatted Thinklab project export.
    See https://thinklab.com/d/191#8

    `project` is a Thinklab project id such as `rephetio`.
    `username` and `password` are Thinklab login credentials.
    """
    export_url = 'https://thinklab.com/p/{}/export.json'.format(project)
    payload = base_payload(session)
    response = session.post(export_url, data=payload, headers=headers)
    try:
        export = response.json()
    except ValueError as error:
        print('\nError parsing {} JSON payload:'.format(project))
        print(response.text)
        raise error
    export['retrieved'] = datetime.datetime.utcnow().isoformat() + 'Z'
    return export

def save_export(export, project, json_dir):
    """
    Write a JSON export to a text file.
    """
    try:
        os.mkdir(json_dir)
    except FileExistsError:
        pass
    path = os.path.join(json_dir, '{}.json'.format(project))
    with open(path, 'wt') as write_file:
        json.dump(export, write_file, ensure_ascii=False, indent=2, sort_keys=True)

def parse_login_json(path):
    """
    Parse JSON file with Thinklab login credentials
    """
    with open(path) as read_file:
        login = json.load(read_file)
    return login['email'], login['password']

if __name__ == '__main__':
    """
    Export Thinklab projects and proposals to a file.

    Example usage:
    ```
    python export.py --username yourname@gmail.com --password yourthebest
    ```
    """
    parser = argparse.ArgumentParser(description='Retrieve Thinklab Project export.')

    parser.add_argument('--username', help='Thinklab login')
    parser.add_argument('--password', help='Thinklab password')
    parser.add_argument('--loginfile', default='login.json', help='Path to JSON file with Thinklab login credentials')

    project_group = parser.add_mutually_exclusive_group(required=True)
    project_group.add_argument('--project', default='rephetio', help='export a specific project given by its project id')
    project_group.add_argument('--all', action='store_true', help='export all thinklab projects')

    parser.add_argument('--outputdir', default='json', help='directory to export JSON files')

    args = parser.parse_args()

    if args.username and args.password:
        username, password = args.username, args.password
    else:
        username, password = parse_login_json(args.loginfile)

    projects = set()
    if args.all:
        for url in project_listing_urls:
            projects.update(retrieve_project_urls(url))
    else:
        projects.add(args.project)
    projects = sorted(projects)

    session = start_session(username, password)
    for project in projects:
        while True:
            try:
                print('Getting project {}'.format(project))
                export = retrieve_project_export(project, session)
                break
            except ValueError:
                time.sleep(10)
        save_export(export, project, args.outputdir)

    session.close()
