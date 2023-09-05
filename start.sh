#!/usr/bin/env bash

ANNOTATION_FILE=${1:-annotations.json}

./ibooktomd.sh $ANNOTATION_FILE

[[ -d docs/_site ]] && rm -rf docs/_site
[[ -d docs/.jekyll-cache ]] && rm -rf docs/.jekyll-cache

cd docs || exit
bundle exec jekyll serve
