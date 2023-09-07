#!/usr/bin/env bash

set -e

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
PROG=${0##*/}
OUTDIR=$DIR/docs

_usage() {
  echo "
  $PROG - Markdown generator for ibook annotations

  USAGE
    \$ $PROG --help
    \$ $PROG [-o DIR] [file]

  OPTIONS
    -h, --help
    -o, --out <DIR>
    -d, --data [book|genre|activity|all]
    -f, --files [annotation|tag|all]"
  exit 1
}

errorMsg() {
  echo "$*"
  exit 1
}

ARGS=($@)

if [[ $# -gt 0 ]]; then
  for i in "${!ARGS[@]}"; do
    j=$((i + 1))
    cur="${ARGS[$i]}"
    next="${ARGS[$j]}"
    case "$cur" in
    -h | --help) _usage ;;
    -o | --out) OUTDIR="${next}" ;;
    -d | --data) CREATE_DATA="${next}" ;;
    -f | --files) CREATE_FILES="${next}" ;;
    -A | --create-all) CREATE_ALL=1 ;;
    *.json) ANNOTATIONS_FILE="${cur}" ;;
    esac
  done
fi

[[ ! -f $ANNOTATIONS_FILE ]] && errorMsg "Cannot find json file"
[[ ! -f $DIR/bookstand.jq ]] && errorMsg "bookstand.jq does not exist"

tabs 4

mkdir -p $OUTDIR/_data

create_book_data() {
  echo "Writing $OUTDIR/_data/books.json"
  jq -L $DIR -r 'include "bookstand"; book_list' $ANNOTATIONS_FILE >$OUTDIR/_data/books.json
}
create_genre_data() {
  echo "Writing $OUTDIR/_data/genre.json"
  jq -L $DIR -r 'include "bookstand"; annotation_tags' $ANNOTATIONS_FILE >$OUTDIR/_data/genre.json
}

create_activity_data() {
  echo "Writing $OUTDIR/_data/activity.json"
  jq -L $DIR -r 'include "bookstand"; annotation_list' $ANNOTATIONS_FILE >$OUTDIR/_data/activity.json
}

create_annotation_files() {
  echo "Creating markdown files to $OUTDIR/_annotations"
  [[ -d $OUTDIR/_annotations ]] && rm -rf $OUTDIR/_annotations
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_annotations \
      'include "bookstand"; create_annotations_markdown($out)' $ANNOTATIONS_FILE
  )
  $DIR/getbookcover.sh -w 150 --get-assetid $ANNOTATIONS_FILE
}

create_tag_files() {
  echo "Creating tag files to $OUTDIR/_tags"
  [[ -d $OUTDIR/_tags ]] && rm -rf $OUTDIR/_tags
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_tags \
      'include "bookstand"; create_tag_markdown($out)' $OUTDIR/_data/genre.json
  )
}

create_all_files() {
  create_annotation_files
  create_tag_files
}

create_all_data() {
  create_book_data
  create_genre_data
  create_activity_data
}

create_all() {
  create_all_files
  create_all_data
}

[[ -n $CREATE_DATA ]] && create_${CREATE_DATA}_data
[[ -n $CREATE_FILES ]] && create_${CREATE_FILES}_files

if [[ -z $CREATE_DATA ]] && [[ -z $CREATE_FILES ]]; then
  CREATE_ALL=1
fi

[[ $CREATE_ALL -eq 1 ]] && create_all
