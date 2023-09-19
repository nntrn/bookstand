#!/usr/bin/env bash

PROG=$0
SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
OUTDIR=${SCRIPT%/*/*}/docs
CACHEDIR=$HOME/.cache/bookstand
MINWIDTH=${MINWIDTH:-200}
FORCE=${FORCE:-0}
CANCEL_ON_ERROR=1
GENREFILE=$OUTDIR/_data/genre.json
RUN_ALL=0
RUN_CREATE_ANNOTATION_PAGES=0
RUN_CREATE_TAG_PAGES=0
RUN_DATA_ACTIVITY=0
RUN_DATA_BOOK=0
RUN_DATA_GENRE=0
RUN_DATA_TASKS=0
RUN_FETCH_BOOKCOVER=0
RUN_FILE_TASKS=0

_usage() {
  echo "
  $PROG - script for building jekyll files for @nntrn/bookstank

  USAGE
    \$ $PROG [OPTIONS] [TASKS] [<ids>...] [file]

  OPTIONS
    -h, --help
    -f, --force
    -o, --out <DIR>         Directory to write files to (default: $OUTDIR)
    -w, --width <PIXELS>    Set image width for --book-cover task

  TASKS
    --books
    --genre               Create \$OUTDIR/_data/genre.json
    --activity            Create \$OUTDIR/_data/activity.json
    --tags                Create files in \$OUTDIR/_tags
    --annotations         Create files in \$OUTDIR/_annotations
    --book-cover          Run task to get book cover
    --all                 Run all tasks
    --all-data-tasks      Same as --book --genre --activity
    --all-file-tasks      Same as --tag and --annotation
    "
  exit 1
}

_success() { echo -e "\e[38;5;28m[✔]\e[0m $*"; }
_error() { echo -e "\e[38;5;160m[✘]\e[0m $*"; }

check_job() {
  RC=$1
  _FUNCNAME="${FUNCNAME[1]:-main}"
  if [[ $RC -eq 0 ]]; then
    _success "${_FUNCNAME}: ${2}"
  else
    _error "${_FUNCNAME}: ${2}"
    [[ $CANCEL_ON_ERROR -eq 1 ]] && exit $RC
  fi
}

delete_empty() { [[ -f $1 ]] && [[ ! -s $1 ]] && rm $1; }

clean() {
  echo "Cleaning $OUTDIR"
  find $OUTDIR -type f -empty -print -delete
}

download_asset_page() {
  mkdir -p $CACHEDIR
  local ASSETID=$1
  APPLE_STORE_URL=https://books.apple.com/us/book
  CACHESTOREHTML=$CACHEDIR/${ASSETID}.html
  if [[ ! -f $CACHESTOREHTML ]]; then
    curl -s --create-dirs -o $CACHESTOREHTML "${APPLE_STORE_URL}/id${ASSETID}"
  fi
  if [[ -f $CACHESTOREHTML ]]; then
    echo "$CACHESTOREHTML"
  fi
}

scrape_book_api() {
  mkdir -p $CACHEDIR
  local ASSETID=$1
  CACHESTOREHTML=$CACHEDIR/${ASSETID}.html
  [[ ! -f $CACHESTOREHTML ]] && CACHESTOREHTML=$(download_asset_page $ASSETID)

  if [[ -f $CACHESTOREHTML ]]; then
    cat $CACHESTOREHTML |
      sed 's,<script,\n<script,g;s,<\/script>,\n</script>,g' |
      sed -n '/<script type="fastboot\/shoebox" id="shoebox-media-api-cache-amp-books">/,/<\/script>/ p' |
      sed s',>{,>\n{,' | grep -vE '<.?script' |
      jq 'to_entries|.[0].value|fromjson | (.d|.[0])
      | {id,type,title:.attributes.name,subtitle,author:.attributes.artistName,isbn,genreNames} + .attributes
      | del(.relationships,.versionHistory,.screenshots,.bookSampleDownloadUrl,.criticalReviews,.editorialArtwork,.type)'
  else
    return 1
  fi
}

get_book_cover() {
  local ASSETID=$1
  mkdir -p $OUTDIR/store
  mkdir -p $OUTDIR/covers
  STOREPATH="${OUTDIR}/store/${ASSETID}.json"
  COVERPATH="${OUTDIR}/covers/${ASSETID}.jpg"
  IMGCACHEPATH="${CACHEDIR}/jpg/${MINWIDTH}/${ASSETID}.jpg"
  RC=0

  if [[ ! -f $COVERPATH ]] || [[ $FORCE -eq 1 ]]; then
    [[ ! -f $STOREPATH ]] && scrape_book_api $ASSETID >$STOREPATH
    if [[ -s $STOREPATH ]]; then
      BOOKCOVERJPG=$(
        jq -r --arg wx ${MINWIDTH:-200} \
          '($wx|tonumber) as $w|.artwork|
        "\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg"' $STOREPATH
      )
      if [[ ! -f $IMGCACHEPATH ]] && [[ -n $BOOKCOVERJPG ]]; then
        curl -s --create-dirs -o "$IMGCACHEPATH" "$BOOKCOVERJPG"
        RC=$?
      fi
    fi
    [[ -f $IMGCACHEPATH ]] && cp $IMGCACHEPATH $COVERPATH
    [[ ! -f $IMGCACHEPATH ]] && RC=1
  fi
  CANCEL_ON_ERROR=0 check_job $RC "Book cover $ASSETID"
}

create_book_data() {
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; book_list' $ANNOTATIONS_FILE >$OUTDIR/_data/books.json
  check_job $? "Write $OUTDIR/_data/books.json"
  [[ ! -f $OUTDIR/_data/.gitignore ]] && echo "*" >$OUTDIR/_data/.gitignore
}

create_genre_data() {
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; annotation_tags' $ANNOTATIONS_FILE >$OUTDIR/_data/genre.json
  check_job $? "Write $OUTDIR/_data/genre.json"
  [[ ! -f $OUTDIR/_data/.gitignore ]] && echo "*" >$OUTDIR/_data/.gitignore
}

create_activity_data() {
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; activity_list' $ANNOTATIONS_FILE >$OUTDIR/_data/activity.json
  check_job $? "Write $OUTDIR/_data/activity.json"
  [[ ! -f $OUTDIR/_data/.gitignore ]] && echo "*" >$OUTDIR/_data/.gitignore
}

create_annotation_files() {
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  [[ -d $OUTDIR/_annotations ]] && [[ $CLEAN_BUILD -eq 1 ]] && rm -rf $OUTDIR/_annotations
  mkdir -p $OUTDIR/_annotations
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_annotations \
      'include "bookstand"; create_annotations_markdown($out)' $ANNOTATIONS_FILE
  )
  check_job $? "Create markdown files to $OUTDIR/_annotations"
  [[ ! -f $OUTDIR/_annotations/.gitignore ]] && echo "*" >$OUTDIR/_annotations/.gitignore
}

create_tag_files() {
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  [[ -d $OUTDIR/_tags ]] && [[ $CLEAN_BUILD -eq 1 ]] && rm -rf $OUTDIR/_tags
  [[ ! -f $OUTDIR/_data/genre.json ]] && create_genre_data
  mkdir -p $OUTDIR/_tags
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_tags \
      'include "bookstand"; create_tag_markdown($out)' $GENREFILE
  )
  check_job $? "Create markdown files $OUTDIR/_tags"
  [[ ! -f $OUTDIR/_tags/.gitignore ]] && echo "*" >$OUTDIR/_tags/.gitignore
}

ARGS=($@)
IDS=()

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
    -c | --clean) CLEAN_BUILD=1 ;;

    --books) RUN_DATA_BOOK=1 ;;
    --genre) RUN_DATA_GENRE=1 ;;
    --activity) RUN_DATA_ACTIVITY=1 ;;
    --tags) RUN_CREATE_TAG_PAGES=1 ;;
    --annotations) RUN_CREATE_ANNOTATION_PAGES=1 ;;
    --book-covers) RUN_FETCH_BOOKCOVER=1 ;;
    --genre-file) GENREFILE="$next" ;;
    --all-data-tasks) RUN_DATA_TASKS=1 ;;
    --all-file-tasks) RUN_FILE_TASKS=1 ;;
    -a | --all) RUN_ALL=1 ;;

    *.json) ANNOTATIONS_FILE="${cur}" ;;
    [0-9][0-9][0-9][0-9][0-9]*) IDS+=("$cur") ;;
    esac
  done
else
  _usage
fi

mkdir -p $CACHEDIR

if [[ -z $ANNOTATIONS_FILE ]]; then
  curl -s -o /tmp/annotations.json https://raw.githubusercontent.com/nntrn/bookstand/assets/annotations.json
  ANNOTATIONS_FILE=/tmp/annotations.json
fi

[[ $((RUN_ALL + RUN_FILE_TASKS + RUN_CREATE_TAG_PAGES)) -gt 0 ]] && create_tag_files
[[ $((RUN_ALL + RUN_FILE_TASKS + RUN_CREATE_ANNOTATION_PAGES)) -gt 0 ]] && create_annotation_files
[[ $((RUN_ALL + RUN_DATA_TASKS + RUN_DATA_BOOK)) -gt 0 ]] && create_book_data
[[ $((RUN_ALL + RUN_DATA_TASKS + RUN_DATA_GENRE)) -gt 0 ]] && create_genre_data
[[ $((RUN_ALL + RUN_DATA_TASKS + RUN_DATA_ACTIVITY)) -gt 0 ]] && create_activity_data

if [[ $((RUN_ALL + RUN_FETCH_BOOKCOVER)) -gt 0 ]]; then
  if [[ ${#IDS[@]} -eq 0 ]] && [[ -f $ANNOTATIONS_FILE ]]; then
    IDS=($(jq -r 'map(select(.ZASSETID)|.ZASSETID)|unique|join("\n")' $ANNOTATIONS_FILE))
  fi
  for id in "${IDS[@]}"; do
    get_book_cover $id
  done
fi
