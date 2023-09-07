#!/usr/bin/env bash

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}

[[ -d docs/_site ]] && rm -rf $DIR/docs/_site
[[ -d docs/.jekyll-cache ]] && rm -rf $DIR/docs/.jekyll-cache

cd $DIR/docs || exit
bundle exec jekyll serve
