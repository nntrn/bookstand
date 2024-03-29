#!/usr/bin/env bash

PROG=$0
SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
OUTDIR=${SCRIPT%/*/*}/docs
CACHEDIR=$HOME/.cache/bookstand
MINWIDTH=${MINWIDTH:-200}
FORCE=${FORCE:-0}
# CANCEL_ON_ERROR=1
RUN_CREATE_ANNOTATION_PAGES=0
RUN_CREATE_TAG_PAGES=0
RUN_DATA_ACTIVITY=0
RUN_DATA_BOOK=0
RUN_DATA_GENRE=0

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
delete_empty() { [[ -f $1 ]] && [[ ! -s $1 ]] && rm $1; }

check_job() {
  RC=$1
  _FUNCNAME="${FUNCNAME[1]:-main}"
  if [[ $RC -eq 0 ]]; then
    _success "${_FUNCNAME}: ${2}"
  else
    _error "${_FUNCNAME}: ${2}"
    # [[ $CANCEL_ON_ERROR -eq 1 ]] && exit $RC
  fi
}

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
    curl -L -s --create-dirs -o $CACHESTOREHTML "${APPLE_STORE_URL}/id${ASSETID}"
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
      | del(.relationships,.versionHistory,.screenshots,.bookSampleDownloadUrl,.criticalReviews,.editorialArtwork,.type,.url)'
  else
    return 1
  fi
}

jq_bc_url() {
  cat $1 | jq -r --arg wx ${MINWIDTH:-200} '($wx|tonumber) as $w|.artwork|
    "\(.url|gsub("{w}.*";""))\($w)x\(.height/(.width/$w)|ceil)bb.jpg"' 2>/dev/null
}

ignore_dir() {
  if [[ ! -f $1/.gitignore ]]; then
    echo "*" >$1/.gitignore
  fi
}

gitignore_dir() {
  if [[ -d $1 ]] && [[ ! -f $1/.gitignore ]]; then
    echo "*" >$1/.gitignore
  fi
}

get_book_cover() {
  local ASSETID=$1
  STOREPATH="${OUTDIR}/store/${ASSETID}.json"
  COVERPATH="${OUTDIR}/covers/${ASSETID}.jpg"
  IMGCACHEPATH="${CACHEDIR}/jpg/${MINWIDTH}/${ASSETID}.jpg"
  RC=0

  mkdir -p $OUTDIR/store
  mkdir -p $OUTDIR/covers
  mkdir -p "${CACHEDIR}/jpg/${MINWIDTH}"

  if [[ ! -f $COVERPATH ]] || [[ $FORCE -eq 1 ]]; then
    [[ ! -f $STOREPATH ]] && scrape_book_api $ASSETID >$STOREPATH
    if [[ -s $STOREPATH ]]; then
      BOOKCOVERJPG="$(jq_bc_url $STOREPATH)"
      if [[ ! -f $IMGCACHEPATH ]] && [[ -n $BOOKCOVERJPG ]]; then
        curl -s --create-dirs -o "$IMGCACHEPATH" "$BOOKCOVERJPG"
        check_job $? "Downloading $BOOKCOVERJPG"
        cp "$IMGCACHEPATH" "$COVERPATH"
      fi
    fi
    [[ -f $IMGCACHEPATH ]] && cp "$IMGCACHEPATH" "$COVERPATH"
  fi
  if [[ ! -f $COVERPATH ]]; then
    check_job 1 "Missing bookcover for $ASSETID"
  fi
}

create_book_data() {
  local OUTPUTFILE=$OUTDIR/_data/books.json
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; book_list' $ANNOTATIONS_FILE >$OUTPUTFILE
  [[ -f $OUTPUTFILE ]] && _success "$OUTPUTFILE" || _error "$OUTPUTFILE"
  gitignore_dir $OUTDIR/_data
}

create_genre_data() {
  local OUTPUTFILE=$OUTDIR/_data/genre.json
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; annotation_tags' $ANNOTATIONS_FILE >$OUTPUTFILE
  [[ -f $OUTPUTFILE ]] && _success "$OUTPUTFILE" || _error "$OUTPUTFILE"
  gitignore_dir $OUTDIR/_data
}

create_activity_data() {
  local OUTPUTFILE=$OUTDIR/_data/activity.json
  mkdir -p $OUTDIR/_data
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  jq -L $DIR 'include "bookstand"; activity_list' $ANNOTATIONS_FILE >$OUTPUTFILE
  [[ -f $OUTPUTFILE ]] && _success "$OUTPUTFILE" || _error "$OUTPUTFILE"
  gitignore_dir $OUTDIR/_data
}

create_store_data() {
  local OUTPUTFILE=$OUTDIR/_data/store.json
  cd $DIR
  cd "$(git rev-parse --show-toplevel)"
  REMOTE_URL=$(git config --local --get remote.origin.url)
  mkdir -p $OUTDIR/_data
  (
    cd "$(mktemp -d)"
    git clone --depth 1 -b assets $REMOTE_URL assets &>/dev/null
    jq -s 'map({
    id,title,subtitle,
    author,isbn,genreNames,pageCount, 
    cover: (.artwork|"\(.url|gsub("{w}.*";""))\(200)x\(.height/(.width/200)|ceil)bb.jpg")
  })' ./assets/store/*.json
  ) >$OUTPUTFILE
  [[ -f $OUTPUTFILE ]] && _success "$OUTPUTFILE" || _error "$OUTPUTFILE"

  gitignore_dir $OUTDIR/_data
}

create_annotation_files() {
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  [[ -d $OUTDIR/_annotations ]] && [[ $CLEAN_BUILD -eq 1 ]] && rm -rf $OUTDIR/_annotations
  mkdir -p $OUTDIR/_annotations
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_annotations \
      'include "bookstand"; create_annotations_markdown($out)' $ANNOTATIONS_FILE
  )
  check_job $? "Create collection files in $OUTDIR/_annotations"
  gitignore_dir $OUTDIR/_annotations
}

create_tag_files() {
  [[ ! -f $ANNOTATIONS_FILE ]] && check_job 1 "Missing file"
  [[ -d $OUTDIR/_tags ]] && [[ $CLEAN_BUILD -eq 1 ]] && rm -rf $OUTDIR/_tags
  [[ ! -f $OUTDIR/_data/genre.json ]] && create_genre_data
  mkdir -p $OUTDIR/_tags
  source <(
    jq -L $DIR -r --arg out $OUTDIR/_tags \
      'include "bookstand"; create_tag_markdown($out)' $OUTDIR/_data/genre.json
  )
  check_job $? "Create collection files $OUTDIR/_tags"
  gitignore_dir $OUTDIR/_tags
}

ARGS=($@)
IDS=()

mkdir -p $CACHEDIR

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

    *.json) ANNOTATIONS_FILE="${cur}" ;;

    [0-9][0-9][0-9][0-9][0-9]*) IDS+=("$cur") ;;

    --books) RUN_DATA_BOOK=1 ;;
    --genre) RUN_DATA_GENRE=1 ;;
    --store) RUN_DATA_STORE=1 ;;
    --activity) RUN_DATA_ACTIVITY=1 ;;

    --tags) RUN_CREATE_TAG_PAGES=1 ;;
    --annotations) RUN_CREATE_ANNOTATION_PAGES=1 ;;

    --book-covers) RUN_DOWNLOAD_BOOKCOVERS=1 ;;

    --all-data-tasks)
      RUN_DATA_BOOK=1
      RUN_DATA_GENRE=1
      RUN_DATA_ACTIVITY=1
      RUN_DATA_STORE=1
      ;;

    --all-file-tasks | --all-collection-tasks)
      RUN_CREATE_TAG_PAGES=1
      RUN_CREATE_ANNOTATION_PAGES=1
      ;;

    esac
  done
else
  _usage
fi

if [[ -z $ANNOTATIONS_FILE ]]; then
  ANNOTATIONS_FILE=$(mktemp)
  curl -s -o $ANNOTATIONS_FILE https://raw.githubusercontent.com/nntrn/bookstand/assets/annotations.json
fi

[[ $RUN_DATA_BOOK -eq 1 ]] && create_book_data
[[ $RUN_DATA_GENRE -eq 1 ]] && create_genre_data
[[ $RUN_DATA_ACTIVITY -eq 1 ]] && create_activity_data
[[ $RUN_DATA_STORE -eq 1 ]] && create_store_data

[[ $RUN_CREATE_TAG_PAGES -eq 1 ]] && create_tag_files
[[ $RUN_CREATE_ANNOTATION_PAGES -eq 1 ]] && create_annotation_files

if [[ $RUN_DOWNLOAD_BOOKCOVERS -eq 1 ]]; then
  if [[ ${#IDS[@]} -eq 0 ]]; then
    IDS=($(jq -r 'map(select(.ZASSETID)|.ZASSETID)|unique|join("\n")' $ANNOTATIONS_FILE))
  fi
  for id in "${IDS[@]}"; do
    get_book_cover $id
  done
fi

# if [[ $((RUN_ALL + RUN_FETCH_BOOKCOVER)) -gt 0 ]]; then
#   if [[ ${#IDS[@]} -eq 0 ]] && [[ -f $ANNOTATIONS_FILE ]]; then
#     IDS=($(jq -r 'map(select(.ZASSETID)|.ZASSETID)|unique|join("\n")' $ANNOTATIONS_FILE))
#   fi
#   for id in "${IDS[@]}"; do
#     get_book_cover $id
#   done
# fi
