set -o errexit

(cd export && python export.py --all)
(cd process && python process.py)
