#!/usr/bin/env bash

set -e

ARGS=("$@")
SCRIPT="$(realpath "$0")"
DIR="${SCRIPT%/*}"
CWD=${DIR%/*}

BUILD_SCRIPT=$DIR/build.sh

cd "$(git -C $DIR rev-parse --show-toplevel)"

if grep -q 'rebuild' <<<"${ARGS[@]}"; then
  echo "Removing _site and .jekyll-cache"
  [[ -d $DIR/docs/_site ]] && rm -rf $CWD/docs/_site
  [[ -d $DIR/docs/.jekyll-cache ]] && rm -rf $CWD/docs/.jekyll-cache
  $BUILD_SCRIPT --all-data-tasks --all-file-tasks --out $CWD/docs
fi

cd $CWD/docs || exit
bundle exec jekyll serve
