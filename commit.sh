#!/usr/bin/env bash
#
# Commit changes to annotations.json to track added lines for a book
#
SCRIPT="$(realpath $0)"
DIR="${SCRIPT%/*}"

cd $DIR

git pull &>/dev/null

DIFFTEXT="$(git diff -U0 annotations.json | grep -Eo '\+[ ]+"ZSORTTITLE.*')"

if [[ -n $DIFFTEXT ]]; then
  CHANGE_SUMMARY="$(echo "$DIFFTEXT" | grep -Eo 'ZSORTTITLE.*' | awk -F: '{a[$2]++;}END{for (i in a)print "+" a[i] i;}')"
  NUMLINES=$(echo "$CHANGE_SUMMARY" | awk 'END{print NR}')
  git add annotations.json covers store

  if [[ $NUMLINES -gt 1 ]]; then
    git commit -m "Add annotations from ${NUMLINES} sources" -m "${CHANGE_SUMMARY}"
  elif [[ $NUMLINES -eq 1 ]]; then
    git commit -m "${CHANGE_SUMMARY}"
  fi
  git log -n 1

else
  echo "Did not detect commitable changes to annotations.json"
  exit 0
fi
