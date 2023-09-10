#!/usr/bin/env bash

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}

if [[ $# -gt 0 ]]; then
  for i in "${!ARGS[@]}"; do
    cur="${ARGS[$i]}"
    case "$cur" in
    --rebuild) REBUILD_BLOG=1 ;;
    esac
  done
fi

if [[ -n $REBUILD_BLOG ]]; then
  echo "Rebuilding..."
  [[ -d docs/_site ]] && rm -rf $DIR/docs/_site
  [[ -d docs/.jekyll-cache ]] && rm -rf $DIR/docs/.jekyll-cache
fi

cd $DIR/docs || exit
bundle exec jekyll serve
