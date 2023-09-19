#!/usr/bin/env bash

set -e

ARGS=("$@")
SCRIPT="$(realpath "$0")"
DIR="${SCRIPT%/*}"

BUILD_SCRIPT=$DIR/build.sh

cd "$(git rev-parse --show-toplevel)"

if grep -q 'rebuild' <<<"${ARGS[@]}"; then
  echo "Removing _site and .jekyll-cache"
  [[ -d $DIR/docs/_site ]] && rm -rf $PWD/docs/_site
  [[ -d $DIR/docs/.jekyll-cache ]] && rm -rf $PWD/docs/.jekyll-cache
  $BUILD_SCRIPT --all-data-tasks --all-file-tasks --out $PWD/docs
fi

cd docs || exit
bundle exec jekyll serve
