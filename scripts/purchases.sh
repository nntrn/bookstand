#!/usr/bin/env bash

OUTDIR=${1:-$PWD}
TMPDIR=$(mktemp -d)
trap 'rm -r "$TMPDIR"' QUIT EXIT

LIBRARY_DBPATH="$(ls -1 $HOME/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/*.sqlite)"

format_book_list() {
  jq 'sort_by(.ZPURCHASEDATE) 
  | map(
    select((.ZPURCHASEDATE|isnormal) and (.ZCONTENTTYPE == 1) and ((.ZSTOREID|length)>0)) 
    | (.ZPURCHASEDATE+978220800) as $localdate
    | {
      assetid: .ZASSETID,
      date: $localdate,
      purchased: ($localdate|todate),
      month: ($localdate | strflocaltime("%b %Y")|ascii_upcase),
      title: .ZTITLE,
      author: .ZAUTHOR,
      genre: .ZGENRE
    }
  )'
}

run_sqlite() {
  local DBPATH="$1"
  local TABLENAME="$2"
  DBPATH_COPY="${TMPDIR:-/tmp}/${DBPATH##*/}"

  cp $DBPATH $DBPATH_COPY
  sqlite3 -json "$DBPATH_COPY" "select * from ${TABLENAME};" ".exit"
}

run_sqlite $LIBRARY_DBPATH ZBKLIBRARYASSET | format_book_list >$OUTDIR/book_purchases.json

jq 'group_by(.date|strflocaltime("%Y %m"))|map({month: .[0].month, count: length, books: map(.title)})' $OUTDIR/book_purchases.json
