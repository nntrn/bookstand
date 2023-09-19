#!/usr/bin/env bash

DIR="$(git rev-parse --show-toplevel)"
ARGS=("$@")

if [[ $# -gt 0 ]]; then
  for i in "${!ARGS[@]}"; do
    cur="${ARGS[$i]}"
    case "$cur" in
    --rebuild) REBUILD_BLOG=1 ;;
    esac
  done
fi

if [[ $REBUILD_BLOG -eq 1 ]]; then
  echo "Removing _site and .jekyll-cache"
  [[ -d $DIR/docs/_site ]] && rm -rf $DIR/docs/_site
  [[ -d $DIR/docs/.jekyll-cache ]] && rm -rf $DIR/docs/.jekyll-cache
fi

cd $DIR/docs || exit
bundle exec jekyll serve
