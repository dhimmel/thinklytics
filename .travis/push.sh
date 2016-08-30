set -o errexit

# Inspired by https://gist.github.com/willprice/e07efd73fb7f13f917ea
git config --global push.default simple
git config --global user.email "travis@travis-ci.com"
git config --global user.name "Travis CI"
git checkout $TRAVIS_BRANCH
git add export process
git commit --message "Auto-export all projects on `date --iso-8601 --universal`

Created by Travis CI build number $TRAVIS_BUILD_NUMBER and job number $TRAVIS_JOB_NUMBER.
https://travis-ci.org/dhimmel/thinklytics/builds/$TRAVIS_BUILD_ID
https://travis-ci.org/dhimmel/thinklytics/jobs/$TRAVIS_JOB_ID

Committed on `date --iso-8601=seconds --universal`.
"
eval `ssh-agent -s`
chmod 600 .travis/deploy_key
ssh-add .travis/deploy_key
git remote set-url origin git@github.com:dhimmel/thinklytics.git
git push --set-upstream origin $TRAVIS_BRANCH
