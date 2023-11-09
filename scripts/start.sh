#!/usr/bin/env bash

set -e

ARGS=("$@")
SCRIPT="$(realpath "$0")"

cd "${SCRIPT%/*}"

if [[ -f build.sh ]]; then
  BUILD_SCRIPT=$PWD/build.sh
fi

DIR="$(git rev-parse --show-toplevel)"
REMOTE_URL=$(git config --local --get remote.origin.url)

get_store_data() {
  (
    cd "$(mktemp -d)"
    git clone --depth 1 -b assets $REMOTE_URL assets &>/dev/null
    jq -s 'map({id,title,subtitle,author,isbn,genreNames,pageCount,
      cover: (.artwork|"\(.url|gsub("{w}.*";""))\(200)x\(.height/(.width/200)|ceil)bb.jpg") 
    })' ./assets/store/*.json
  )
}

if grep -q 'rebuild' <<<"${ARGS[@]}"; then
  echo "Removing _site and .jekyll-cache"
  [[ -d $DIR/docs/_site ]] && rm -rf $DIR/docs/_site
  [[ -d $DIR/docs/.jekyll-cache ]] && rm -rf $DIR/docs/.jekyll-cache
  $BUILD_SCRIPT --all-data-tasks --all-file-tasks --out $DIR/docs
  get_store_data >$DIR/docs/_data/store.json
fi

cd $DIR/docs || exit
bundle exec jekyll serve
