# Thinklab project exports and analytics

[Thinklab](http://thinklab.com/) is a platform for collaborative online open science. This repository retrieves Thinklab [project exports](http://thinklab.com/discussion/discussion-summary-statistics-for-illustrating-project-impact/191#4). Future releases will perform analytics on the content.

## Usage

The export for a specific project can be retrieved using:

```sh
python export.py --login login.json --project rephetio --output export/rephetio.json
```

Users need to create a `login.json` file with their personal Thinklab credentials. [`login-template.json`](login-template.json) provides a template.

## License

Thinklab user content is licensed as [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/ "Creative Commons · Attribution 4.0 International"). Original content in this repository is released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/ "Creative Commons · CC0 1.0 Universal · Public Domain Dedication").
