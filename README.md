# Analytics for the _Thinklab_ platform

[_Thinklab_](https://thinklab.com/) is a platform for collaborative online open science. This repository exports and stores _Thinklab_ content as well as providing basic analytics for _Thinklab_ projects.

## Repository structure

+ `export` retrieves Thinklab [project exports](https://thinklab.com/discussion/discussion-summary-statistics-for-illustrating-project-impact/191#4).

+ `process` creates tabular summaries of project activity and contributions.

+ `viz` contains R visualizations of project activity.

## Scheduled export

[![Build Status](https://travis-ci.org/dhimmel/thinklytics.svg?branch=master)](https://travis-ci.org/dhimmel/thinklytics)

This repository uses [Travis CI](https://travis-ci.org/dhimmel/thinklytics "dhimmel/thinklytics on Travis CI") to perform a daily export of all Thinklab projects. Travis CI is configured to perform a [cron-scheduled](https://docs.travis-ci.com/user/cron-jobs/ "Travis CI Cron Jobs") build every day. The build, which is configured using [`.travis.yml`](.travis.yml), executes [`run.sh`](run.sh) inside a Docker container containing this repository's [conda environment](docker/spec-file.txt). If the Travis CI build succeeds, the exported and processed datasets are pushed back to this repository.

## License

_Thinklab_ user content is licensed as [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/ "Creative Commons · Attribution 4.0 International"). Original content in this repository is released under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/ "Creative Commons · CC0 1.0 Universal · Public Domain Dedication").
