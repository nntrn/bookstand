#!/usr/bin/env bash

_usage() {
  echo "
  getbookcover.sh - get apple book cover

  USAGE
    \$ getbookcover.sh --help
    \$ getbookcover.sh [-m MINIMUM_WIDTH] [-o OUTPUT_DIR] [<asset_id>..]

  EXAMPLE

    \$ IDS=(720805457 357927096 1320762791)
    \$ getbookcover.sh \${IDS[@]}

    \$ getbookcover.sh --get-assetid annotations.json ZASSETID

  OPTIONS
    -h, --help                    Shows this help message
    -f, --force                   Force rerun, also FORCE=1
    -w, --min-width <int>         Set minimum width for image, also MINWIDTH=x
    -o, --out <path>              Directory to save images to, also OUTDIR=x
    --get-assetid <file> [field]  JSON file to get asset ids
                                  use JQ_ASSETID_KEY=x to set field. Default is ZASSETID
  "
  exit 1
}

TODAY=$(date +%F)

[[ 6 == "$(curl -s -w '%{exitcode}' -o /dev/null example.com)" ]] &&
  ISOFFLINE=1

CACHEDIR=$HOME/.cache/bookstand
BOOKCOVERDIR="$HOME/Library/Containers/com.apple.iBooksX/Data/Library/Caches/BCCoverCache-1/BICDiskDataStore"
BOOKCOVERIMAGESETS="$HOME/Library/Containers/com.apple.iBooksX/Data/Library/Caches/BCCoverCache-1/imagesets.sqlite"

IMAGEENTRYJSON=$CACHEDIR/ZBICIMAGEENTRY-${TODAY}.json
BCGROUPBYASSETID=$CACHEDIR/imagesets-${TODAY}.json
BCIMAGEPATHS=$CACHEDIR/BICDiskDataStore-${TODAY}.txt

MINWIDTH=${MINWIDTH:-200}
FORCE=${FORCE:-0}
OUTDIR=${OUTDIR:-docs/assets/artwork}
JQ_ASSETID_KEY=${JQ_ASSETID_KEY}

export MINWIDTH FORCE OUTDIR JQ_ASSETID_KEY
export DIDRUN_LOCAL_PRETASK DIDRUN_REMOTE_PRETASK

_log() { echo -e "\033[0;${3:-35}m[${1}]\033[0m ${2}" 3>&2 2>&1 >&3 3>&-; }

run_pretask() {
  mkdir -p $CACHEDIR

  if [[ -d $BOOKCOVERDIR ]]; then
    if [[ ! -f $BCIMAGEPATHS ]] || [[ $FORCE -eq 1 ]]; then
      _log PRETASK "Run local pretask => $BCIMAGEPATHS"
      find $BOOKCOVERDIR -type f -name "*.jpg" 2>/dev/null |
        awk -F'|' "{ if (\$3 >= $MINWIDTH) print \$0 }" |
        sort >$BCIMAGEPATHS
    fi
  fi

  if [[ -f $BOOKCOVERIMAGESETS ]]; then
    if [[ ! -f $BCGROUPBYASSETID ]] || [[ $FORCE -eq 1 ]]; then
      _log PRETASK "Run sql task => $BCGROUPBYASSETID" 33
      sqlite3 -json "$BOOKCOVERIMAGESETS" \
        ".output $IMAGEENTRYJSON" "
        select
          substr(ZENTRYLOCATION, 0,instr(ZENTRYLOCATION, '|')) as assetid,
          ZWIDTH as width,
          ZDATASTOREINFORMATION as  url
        from ZBICIMAGEENTRY
        where
          ZDATASTOREINFORMATION like 'http%'
          and ZDATASTOREINFORMATION like '%jpg';" \
        ".exit"
      jq 'group_by(.assetid)
      | map({"\(.[0].assetid)": (map({width,url})|unique|sort_by(.width)) })
      | add' $IMAGEENTRYJSON >$BCGROUPBYASSETID
    fi
  fi
}

get_local() {
  local ASSETID=${1:?}
  local COPYTOPATH="${2:?}"

  LOCAL_IMAGE_PATH="$(cat $BCIMAGEPATHS | grep $ASSETID | head -n 1)"
  if [[ -n $LOCAL_IMAGE_PATH ]]; then
    cp "$LOCAL_IMAGE_PATH" "$COPYTOPATH"
    _log $ASSETID "Copied from $LOCAL_IMAGE_PATH"
  fi
}

scrape_image_url() {
  local ASSETID=$1
  APPLE_STORE_URL=https://books.apple.com/us/book
  CACHESTOREHTML=$CACHEDIR/store/${ASSETID}.html
  if [[ ! -f $CACHESTOREHTML ]]; then
    _log SCRAPE "$CACHESTOREHTML" 36
    curl -s -L --create-dirs -o $CACHESTOREHTML "${APPLE_STORE_URL}/id${ASSETID}"
  fi
  IMAGE="$(cat $CACHESTOREHTML | grep -oE 'https[^\ ]+\.(png|jpg)' | grep 'x0w.jpg' | head -n 1)"
  echo "$IMAGE"
}

get_remote() {
  local ASSETID=$1
  local COPYTOPATH="$2"

  if [[ -f $BCGROUPBYASSETID ]]; then
    JQ_IMAGE_URL='(.[$assetid]|map(select(.width > ((env.MINWIDTH//"0")|tonumber)))|first|.url)?'
    IMAGE_URL="$(jq -r --arg assetid $ASSETID "$JQ_IMAGE_URL" $BCGROUPBYASSETID)"
    [[ -z $IMAGE_URL ]] && IMAGE_URL=$(scrape_image_url $ASSETID)
    if [[ -n $IMAGE_URL ]]; then
      CHKSUM=$(echo "$IMAGE_URL" | md5sum | awk '{print $1}')
      CACHEFILE=$CACHEDIR/$CHKSUM
      if [[ ! -f $CACHEFILE ]]; then
        _log $ASSETID "Downloading $IMAGE_URL" 36
        curl -s --create-dirs -o $CACHEFILE "$IMAGE_URL"
      fi
      if [[ -f $CACHEFILE ]]; then
        cp $CACHEFILE "$COPYTOPATH"
        _log $ASSETID "Copied from $CACHEFILE" 36
      fi
    fi
  fi
}

bcmanager() {
  ASSETID=$1
  ASSETOUTPUT="$OUTDIR/${ASSETID}.jpg"
  [[ -d $OUTDIR ]] && mkdir -p $OUTDIR
  if [[ ! -f $ASSETOUTPUT ]] || [[ $FORCE -eq 1 ]]; then
    [[ -z $ISOFFLINE ]] && get_remote $ASSETID "$ASSETOUTPUT"
    [[ ! -f $ASSETOUTPUT ]] && get_local $ASSETID "$ASSETOUTPUT"
    [[ ! -f $ASSETOUTPUT ]] && _log $ASSETID "Cannot find book cover url" 32
  else
    _log SKIP "$ASSETOUTPUT already exists. Delete or rerun with --force to overwrite" 33
  fi
}

get_assetid_from_file() {
  JQFIELD=${2:-$JQ_ASSETID_KEY}
  export field=${JQFIELD:-"ZASSETID"}
  # shellcheck disable=SC2207
  IFS=$'\n' BOOKIDS=($(jq -r 'map(.[env.field]|select(length > 0))|unique|join("\n")' $1))
  for i in "${BOOKIDS[@]}"; do
    if grep -qE '^[0-9]{5,}$' <<<"$i"; then
      bcmanager $i
    else
      echo "Invalid input: $i"
    fi
  done
  exit 0
}

ARGS=($@)

if [[ $# -gt 0 ]]; then
  run_pretask
  mkdir -p $CACHEDIR
  for i in "${!ARGS[@]}"; do
    j=$((i + 1))
    next="${ARGS[$j]}"
    case "${ARGS[$i]}" in
    -h | --help) _usage ;;
    -o | --out) OUTDIR="$next" ;;
    -f | --force) FORCE=1 ;;
    -w | --min-width) MINWIDTH=$next ;;
    --get-assetid) get_assetid_from_file "${ARGS[@]:$j}" ;;
    [0-9][0-9][0-9][0-9][0-9]*) bcmanager ${ARGS[$i]} ;;
    esac
  done
  echo "Saved to $OUTDIR"
fi
