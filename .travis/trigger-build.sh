# Triggers a Travis build using the Travis API
# https://docs.travis-ci.com/user/triggering-builds

body='{
"request": {
  "branch":"master"
}}'

curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token `travis token --org`" \
  -d "$body" \
  https://api.travis-ci.org/repo/dhimmel%2Fthinklytics/requests
