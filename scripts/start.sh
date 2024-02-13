#!/usr/bin/env bash

set -e

ARGS=("$@")
SCRIPT="$(realpath "$0")"
DIR="${SCRIPT%/*}"
CWD=${DIR%/*}

BUILD_SCRIPT=$DIR/build.sh

cd "$(git -C $DIR rev-parse --show-toplevel)"

if grep -q 'rebuild' <<<"${ARGS[@]}"; then
  for dir in $CWD/docs/_annotations $CWD/docs/_site $CWD/docs/.jekyll-cache; do
    if [[ -d $dir ]]; then
      echo "removing $dir"
      rm -rf $dir
    fi
  done
  $BUILD_SCRIPT --all-data-tasks --all-file-tasks --out $CWD/docs
fi

cd $CWD/docs || exit
bundle exec jekyll serve
