#!/usr/bin/env bash

PROG=$0

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
cd $DIR
TOPLEVEL="$(git rev-parse --show-toplevel)"
OUTDIR=$TOPLEVEL/docs
CACHEDIR=$HOME/.cache/bookstand
ARGS=($@)
IDS=()

_success() { echo -e "\e[38;5;28m[✔] ${FUNCNAME[2]}: \e[0m\e[38;5;8m$*\e[0m" 3>&2 2>&1 >&3 3>&-; }
_error() { echo -e "\e[38;5;160m[✘] ${FUNCNAME[2]}: \e[0m\e[38;5;8m$*\e[0m" 3>&2 2>&1 >&3 3>&-; }
_chksum() { echo "$(echo "$@" | md5sum | awk '{print $1}')"; }

_validate() {
  RC=$1
  if [[ $RC -eq 0 ]]; then
    _success "${2}"
  else
    _error "${2}"
  fi
}

_curl() {
  CHKSUM=$(_chksum "$@")
  CACHEFILE=$HOME/.cache/bookstand/$CHKSUM
  args=(-s --create-dirs -o "$CACHEFILE" "$@")

  [[ ! -f $CACHEFILE ]] && curl "${args[@]}"
  if [[ -f $CACHEFILE ]]; then echo "$CACHEFILE"; else return 1; fi
}

download_asset_page() {
  local ASSETID=$1
  APPLE_STORE_URL="https://books.apple.com/us/book/id${ASSETID}"
  CACHESTOREHTML=$(_curl "$APPLE_STORE_URL")

  if $? -eq 0 && grep -q shoebox-media-api-cache-amp-books <$CACHESTOREHTML; then
    echo $CACHESTOREHTML
  else
    return 1
  fi
}

get_book_api() {
  local ASSETID=$1
  APPLE_STORE_URL="https://books.apple.com/us/book/id${ASSETID}"
  CACHESTOREHTML=$(_curl "$APPLE_STORE_URL")

  [[ -f $CACHESTOREHTML ]] &&
    cat $CACHESTOREHTML |
    sed 's,<script,\n<script,g;s,<\/script>,\n</script>,g' |
      sed -n '/<script type="fastboot\/shoebox" id="shoebox-media-api-cache-amp-books">/,/<\/script>/ p' |
      sed s',>{,>\n{,' | grep -vE '<.?script' |
      jq 'to_entries|.[0].value|fromjson | (.d|.[0])
      | {id,type,title:.attributes.name,subtitle,author:.attributes.artistName,isbn,genreNames} + .attributes
      | del(.relationships,.versionHistory,.screenshots,.bookSampleDownloadUrl,
        .criticalReviews,.editorialArtwork,.type,.url)' 2>/dev/null
}

get_book_cover() {
  local ASSETID=$1
  local STOREJSON="$2"
  local OUTPUTPATH="$OUTDIR/covers/${ASSETID}.jpg"
  local BCCACHEPATH="${CACHEDIR}/jpg/${MINWIDTH}/${ASSETID}.jpg"
  local LOCALIMGPATH=
  local IMAGEURL=

  if [[ ! -f $OUTPUTPATH ]] || [[ $FORCE -eq 1 ]]; then
    if [[ -f $STOREJSON ]]; then
      IMAGEURL=$(
        jq -r --arg wx ${MINWIDTH:-200} '($wx|tonumber) as $w|.artwork|
        "\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg"' $STOREJSON
      )
    fi

    [[ -n $IMAGEURL ]] && LOCALIMGPATH=$(_curl $IMAGEURL)
    if [[ -f $LOCALIMGPATH ]]; then
      cp "$LOCALIMGPATH" $OUTDIR/bookcovers/${id}.jpg
    else
      return 1
    fi
  fi
}

get_book_cover() {
  local ASSETID=$1
  local OUTPUTPATH="$OUTDIR/covers/${ASSETID}.jpg"
  CHKSUM=$(_chksum)
  IMGCACHEPATH="${CACHEDIR}/jpg/${MINWIDTH}/${ASSETID}.jpg"

  if [[ ! -f $OUTPUTPATH ]] || [[ $FORCE -eq 1 ]]; then
    CACHESTOREHTML="$(download_asset_page $ASSETID)"
    mkdir -p $OUTDIR/store

    _curl "$BOOKCOVERURL"

  fi

  if [[ ! -f $OUTPATH ]] || [[ $FORCE -eq 1 ]]; then
    scrape_book_api $ASSETID >$OUTPATH
  fi
  if [[ -s $OUTPATH ]]; then
    BOOKCOVERURL=$(
      jq -r --arg wx ${MINWIDTH:-200} '($wx|tonumber) as $w | .artwork |
        "\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg"' $OUTPATH
    )
    if [[ ! -f $IMGCACHEPATH ]] && [[ -n $BOOKCOVERURL ]]; then
      curl -s --create-dirs -o "$IMGCACHEPATH" "$BOOKCOVERURL"
    fi
  fi
  if [[ -f $IMGCACHEPATH ]]; then
    mkdir -p $OUTDIR/covers
    cp "$IMGCACHEPATH" "$OUTDIR/covers/${ASSETID}.jpg"
  else
    return 1
  fi
}

download() {
  local ASSETID=$1
  local STORE_FILEPATH=$OUTDIR/store/${ASSETID}.json
  local BC_FILEPATH=$OUTDIR/covers/${ASSETID}.jpg

  if [[ ! -f $STORE_FILEPATH ]] || [[ $FORCE -eq 1 ]]; then
    get_book_api $ASSETID >$STORE_FILEPATH
    _validate $? "Store data $STORE_FILEPATH"
  fi
  if [[ ! -f $BC_FILEPATH ]] || [[ $FORCE -eq 1 ]]; then
    get_book_cover $ASSETID "$OUTDIR/store/${ASSETID}.json"
    _validate $? "Store data $STORE_FILEPATH"
  fi
}

cd $TOPLEVEL

if [[ $# -gt 0 ]]; then
  for i in "${!ARGS[@]}"; do
    j=$((i + 1))
    cur="${ARGS[$i]}"
    next="${ARGS[$j]}"

    case "$cur" in
    -h | --help) _usage ;;
    -f | --force) FORCE=1 ;;
    -o | --out) OUTDIR="${next}" ;;
    -w | --width) MINWIDTH=$next ;;

    *.json) ANNOTATIONS_FILE="${cur}" ;;
    [0-9][0-9][0-9][0-9][0-9]*) IDS+=("$cur") ;;
    esac
  done
fi

if [[ ${#IDS[@]} -eq 0 ]] && [[ -f $ANNOTATIONS_FILE ]]; then
  _ids="$(jq -r 'map(select(.ZASSETID)|.ZASSETID)|unique|join("\n")' $ANNOTATIONS_FILE)"
  IDS=("$_ids")
fi

mkdir -p $OUTDIR/{covers,store}

for id in "${IDS[@]}"; do
  download "$id"
done
