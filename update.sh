#!/usr/bin/env bash
# update annotations.json and download book cover and store data

# set -e
SCRIPT=$(realpath $0)
DIR=${SCRIPT%/*}

_log() { echo -e "\033[0;${2:-33}m$1\033[0m" 3>&2 2>&1 >&3 3>&-; }

_checkfile() {
  RELPATH="${1//$PWD/.}"
  if [[ -f $1 && -s $1 ]]; then
    echo -e "${RELPATH} \033[0;32m✔\033[0m" 3>&2 2>&1 >&3 3>&-
    return 0
  elif [[ -f $1 ]]; then
    echo -e "${RELPATH} \033[0;31m✘ FILE IS EMPTY\033[0m... Deleting" 3>&2 2>&1 >&3 3>&-
    rm $1
    return 1
  else
    echo -e "${RELPATH} \033[0;31m✘ DOES NOT EXIST\033[0m" 3>&2 2>&1 >&3 3>&-
    return 1
  fi
}

sync_ibooks() {
  open -a Books
  echo " Starting █"
  for i in {1..3}; do
    sleep 10
    jq -nr --arg ix $i '(100*($ix|tonumber)/3) as $i|"\($i|round)%" as $c|[" " * (8-($c|length)),$c,"█"*(25*($i/100))]|join(" ")'
  done
  osascript -e 'quit app "Books"'
}

scrape_book_api() {
  curl -L -s "https://books.apple.com/us/book/id${1:?}" --fail |
    sed 's,<script,\n<script,g;s,<\/script>,\n</script>,g;s,>{,>\n{,g' |
    sed -n '/<script type="fastboot\/shoebox" id="shoebox-media-api-cache-amp-books">/,/<\/script>/ p' |
    grep -vE '<.?script' |
    jq 'values|map(fromjson.d)|last[]
      | del(.relationships)
      | {id,type,title:.attributes.name,subtitle,author:.attributes.artistName,isbn,genreNames} + .attributes
      ' 2>/dev/null
}

get_artwork_url() {
  cat $1 | jq -r '200 as $w 
  | if .artwork.url
  then (.artwork|"\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg")
  else "" end'
}

get_artwork_cover() {
  local STOREPATH=store/$1.json
  local COVERPATH=covers/$1.jpg

  if [[ -f $STOREPATH ]]; then
    ARTWORK_URL="$(get_artwork_url $STOREPATH)"
    _log "Downloading artwork cover from $ARTWORK_URL"
    if [[ -n $ARTWORK_URL ]]; then
      curl -s --create-dirs -o $COVERPATH "$ARTWORK_URL" --fail
    fi
  fi
}

run_jobs_for_asset() {
  BOOKID=${1:?}
  STORE_PATH=store/${BOOKID}.json
  COVER_PATH=covers/${BOOKID}.jpg

  if [[ $BOOKID == [0-9]* ]]; then
    [[ -f $STORE_PATH && ! -s $STORE_PATH ]] && rm $STORE_PATH
    [[ ! -f $STORE_PATH ]] && scrape_book_api $BOOKID >$STORE_PATH
    [[ ! -f $COVER_PATH && -s $STORE_PATH ]] && get_artwork_cover $BOOKID
    _checkfile $STORE_PATH
    _checkfile $COVER_PATH
  else
    _log "ERROR: $BOOKID is not a valid id" 31
  fi
}

{
  cd $DIR
  git pull
  sync_ibooks
  queryibooks >annotations.json
  mkdir -p {covers,store}

  ASSET_IDS=($(git diff -U0 annotations.json | grep -Eo '\+[ ]+"ZASSETID": "[0-9]+"' | sort -u | awk -F'"' '{print $(NF-1)}'))

  echo "ASSET IDS: ${#ASSET_IDS[@]}"

  for i in "${ASSET_IDS[@]}"; do
    _log "Start job for $i" 36
    run_jobs_for_asset $i
  done

  find . -type f ! -path "*/.git/*" -empty -print -delete
}
