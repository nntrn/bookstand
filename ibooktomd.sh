#!/usr/bin/env bash

set -e

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
PROG=${0##*/}
OUTDIR=docs/_annotations
DATADIR=docs/_data
export OUTDIR

_usage() {
  echo "
  $PROG - Markdown generator for ibook annotations

  USAGE
    \$ $PROG --help
    \$ $PROG [-o DIR] [file]

  OPTIONS
    -h, --help        Shows this help message
    -o, --out         Directory to"
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
    *.json) ANNOTATIONS_FILE="${cur}" ;;
    esac
  done
fi

[[ ! -f $ANNOTATIONS_FILE ]] && errorMsg "Cannot find json file"
[[ ! -f $DIR/bookstand.jq ]] && errorMsg "bookstand.jq does not exist"

[[ -d ${OUTDIR}-old ]] && rm -rf ${OUTDIR}-old
[[ -d $OUTDIR ]] && mv $OUTDIR ${OUTDIR}-old

tabs 2
mkdir -p $OUTDIR
mkdir -p $DATADIR

echo "Writing $DATADIR/books.json"
jq -L $DIR -r 'include "bookstand"; book_list' $ANNOTATIONS_FILE >$DATADIR/books.json

echo "Writing $DATADIR/genre.json"
jq -L $DIR -r 'include "bookstand"; annotation_tags' $ANNOTATIONS_FILE >$DATADIR/genre.json

echo "Writing $DATADIR/activity.json"
jq -L $DIR -r 'include "bookstand"; annotation_list' $ANNOTATIONS_FILE >$DATADIR/activity.json

echo "Creating markdown files to $OUTDIR"
source <(jq -L $DIR -r 'include "bookstand"; create_markdown|join("\n\n")' $ANNOTATIONS_FILE)

if [[ -d ${OUTDIR}-old ]]; then
  sdiff -s <(ls -1 $OUTDIR) <(ls -1 ${OUTDIR}-old)
  rm -rf ${OUTDIR}-old
fi

mkdir -p docs/_tags
source <(jq -r 'map({ title:.name, content: (["---","title: \(.name)","layout: tag","---"]|join("\n")) })
| map(@sh "echo -e \(.content) >"+ "docs/_tags/\(.title).html")
| join("\n\n")' $DATADIR/genre.json)
