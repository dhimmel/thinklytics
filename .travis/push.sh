set -o errexit

# Inspired by https://gist.github.com/willprice/e07efd73fb7f13f917ea
git config --global push.default simple
git config --global user.email "travis@travis-ci.com"
git config --global user.name "Travis CI"
git checkout $TRAVIS_BRANCH
git add export process
git commit --message "Auto-export all projects on `date --iso-8601 --universal`

Travis build $TRAVIS_BUILD_NUMBER.
Committed on `date --iso-8601=seconds --universal`.
"
git remote set-url origin https://${GH_TOKEN}@github.com/dhimmel/thinklytics.git
git push --set-upstream origin $TRAVIS_BRANCH
