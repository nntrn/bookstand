#!/usr/bin/env bash
# shellcheck disable=SC2207
#
# USAGE
#   Commit changes to annotations.json to track added lines for a book
#
# RUN
#   $ ./commit.sh
#
SCRIPT="$(realpath $0)"
DIR="${SCRIPT%/*}"

cd $DIR || exit 1

if [[ -n "$(git ls-files -m annotations.json)" ]]; then

  IFS=$'\n' CHANGE_SUMMARY=($(
    grep -Eo 'ZSORTTITLE.*' <(git diff annotations.json | tr -d '"') |
      awk -F: '{a[$2]++;}END{for (i in a)print "+" a[i] i;}'
  ))

  git add annotations.json

  if [[ ${#CHANGE_SUMMARY[@]} -gt 1 ]]; then
    git commit -m "Add annotations from ${#CHANGE_SUMMARY[@]} sources" -m "$(printf "%s\\n" "${CHANGE_SUMMARY[@]}")"
  elif [[ ${#CHANGE_SUMMARY[@]} -eq 1 ]]; then
    git commit -m "${CHANGE_SUMMARY[@]}"
  fi

  # output commit before exiting
  git log -n 1

else
  echo "No changes to annotations.json"
fi
