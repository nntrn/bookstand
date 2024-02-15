#!/usr/bin/env bash
# update annotations.json and download book cover and store data

set -e
SCRIPT=$(realpath $0)
DIR=${SCRIPT%/*}

sync_ibooks() {
  open -a Books
  echo "Sleeping ....."
  sleep 30
  echo "Done!"
  osascript -e 'quit app "Books"'
}

scrape_book_api() {
  curl -L -s "https://books.apple.com/us/book/id${1:?}" |
    sed 's,<script,\n<script,g;s,<\/script>,\n</script>,g;s,>{,>\n{,g' |
    sed -n '/<script type="fastboot\/shoebox" id="shoebox-media-api-cache-amp-books">/,/<\/script>/ p' |
    grep -vE '<.?script' |
    jq '(if (length>0) then . else halt_error(1) end)
      | to_entries| .[0].value | fromjson | (.d|.[0])
      | {id,type,title:.attributes.name,subtitle,author:.attributes.artistName,isbn,genreNames} + .attributes
      | del(.versionHistory,.screenshots,.bookSampleDownloadUrl,.editorialArtwork,.url)' 2>/dev/null
}

get_artwork_url() {
  cat $1 | jq -r '((env.IMGWIDTH|tonumber)? // 200) as $w |
  if .artwork.url
  then (.artwork|"\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg")
  else "" end'
}

scrape_job() {
  local bookid=$1
  local STORE_PATH=store/${bookid:?}.json
  local COVER_PATH=covers/${bookid:?}.jpg
  mkdir -p {store,covers}
  if [[ $UPDATE_SCRAPE -eq 1 || ! -f $STORE_PATH || ! -s $STORE_PATH ]]; then
    echo "$bookid: Scraping book data"
    scrape_book_api $bookid >$STORE_PATH
  else
    echo "$STORE_PATH exists"
  fi
  ARTWORK_URL="$(get_artwork_url $STORE_PATH)"
  if [[ ! -f $COVER_PATH && -n $ARTWORK_URL ]]; then
    echo "$bookid: Downloading $ARTWORK_URL"
    curl -s --create-dirs -o $COVER_PATH "$ARTWORK_URL"
  else
    echo "$COVER_PATH exists"
  fi
}

RUN_SYNC=${RUN_SYNC:-1}
RUN_QUERY=${RUN_QUERY:-1}
RUN_SCRAPE=${RUN_SCRAPE:-1}
UPDATE_SCRAPE=${UPDATE_SCRAPE:-0}

while [ "$1" != "" ]; do
  case $1 in
  --skip-sync) RUN_SYNC=0 ;;
  --skip-query) RUN_QUERY=0 ;;
  --skip-scrape) RUN_SCRAPE=0 ;;
  --update) UPDATE_SCRAPE=1 ;;
  esac
  shift 1
done

cd $DIR
git pull

[[ $RUN_SYNC -eq 1 ]] && sync_ibooks
[[ $RUN_QUERY -eq 1 ]] && queryibooks >annotations.json
if [[ $RUN_SCRAPE -eq 1 ]]; then
  ASSET_IDS=($(git diff -U0 annotations.json | grep -Eo '\+[ ]+"ZASSETID.*' | sort -u | awk -F'"' '{print $(NF-1)}'))
  for i in "${ASSET_IDS[@]}"; do scrape_job $i; done
fi
