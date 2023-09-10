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

_log() { echo -e "\e[0;${2:-35}m${1}\e[0m" 3>&2 2>&1 >&3 3>&-; }

errorMsg() {
  echo "$*"
  exit 1
}

cancel_on_error() {
  RC=$1
  if [[ $RC -eq 0 ]]; then
    echo -e "\e[38;5;28m[✔]\e[0m $2"
  else
    echo -e "\e[38;5;160m[✘]\e[0m $2 - $RC"
    exit $RC
  fi
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
    *.json) ANNOTATIONS_FILE="${cur}" ;;
    esac
  done
fi

[[ ! -f $ANNOTATIONS_FILE ]] && errorMsg "Cannot find json file"
[[ ! -f $DIR/bookstand.jq ]] && errorMsg "bookstand.jq does not exist"

create_book_data() {
  jq -L $DIR -r 'include "bookstand"; book_list' $ANNOTATIONS_FILE >$OUTDIR/_data/books.json
  cancel_on_error $? "Writing $OUTDIR/_data/books.json"
}
create_genre_data() {
  jq -L $DIR -r 'include "bookstand"; annotation_tags' $ANNOTATIONS_FILE >$OUTDIR/_data/genre.json
  cancel_on_error $? "Writing $OUTDIR/_data/genre.json"
}

create_activity_data() {
  jq -L $DIR -r 'include "bookstand"; activity_list' $ANNOTATIONS_FILE >$OUTDIR/_data/activity.json
  cancel_on_error $? "Writing $OUTDIR/_data/activity.json"
}

create_annotation_files() {
  echo "Creating markdown files to $OUTDIR/_annotations"
  [[ -d $OUTDIR/_annotations ]] && rm -rf $OUTDIR/_annotations
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_annotations \
      'include "bookstand"; create_annotations_markdown($out)' $ANNOTATIONS_FILE
  )
}

create_tag_files() {
  echo "Creating tag files to $OUTDIR/_tags"
  [[ -d $OUTDIR/_tags ]] && rm -rf $OUTDIR/_tags
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_tags \
      'include "bookstand"; create_tag_markdown($out)' $OUTDIR/_data/genre.json
  )
}

main() {
  tabs 4

  mkdir -p $OUTDIR/_data

  create_annotation_files
  create_tag_files
  create_book_data
  create_genre_data
  create_activity_data

  $DIR/getbookcover.sh -w 150 --get-assetid $ANNOTATIONS_FILE
}

main
