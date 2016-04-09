import argparse
import json
import datetime
import os

import requests

def retrieve_project_export(project, username, password):
    """
    Retrieve a JSON-formatted Thinklab project export.
    See http://thinklab.com/d/191#8

    `project` is a Thinklab project id such as `rephetio`.
    `username` and `password` are Thinklab login credentials.
    """
    with requests.Session() as session:
        login_url = 'http://thinklab.com/login'
        session.get(login_url)
        csrf_token = session.cookies['csrftoken']
        payload = {
            'email': username,
            'password': password,
            'csrfmiddlewaretoken': csrf_token,
        }
        session.post(login_url, data=payload)

        export_url = 'http://thinklab.com/p/{}/export.json'.format(project)
        response = session.get(export_url)
        export = response.json()

    export['retrieved'] = datetime.datetime.utcnow().isoformat() + 'Z'
    return export

def save_export(export, project, json_dir):
    """
    Write a JSON export to a text file.
    """
    os.makedirs(json_dir, exist_ok=True)
    with open(os.path.join(json_dir, "{}.json".), 'wt') as write_file:
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
    Export a Thinklab project to a file.

    Example usage:
    ```
    python export.py --loginfile login.json --project rephetio --output export/rephetio.json
    ```
    """
    parser = argparse.ArgumentParser(description='Retrieve Thinklab Project export.')
    parser.add_argument('--username', default='', help='Thinklab login')
    parser.add_argument('--password', default='', help='Thinklab password')
    parser.add_argument('--loginfile', default='login.json', help='alternatively, path to file with Thinklab login credentials')
    parser.add_argument('--project', default='rephetio', help='project id')
    parser.add_argument('--outputdir', default='exported', help='path to export to')
    args = parser.parse_args()

    if (args.username == '') & (args.password == ''):
        username, password = parse_login_json(args.loginfile)
    else:
        username, password = args.username, args.password

    project = args.project
    export = retrieve_project_export(project, username, password)
    save_export(export, project, args.outputdir)
