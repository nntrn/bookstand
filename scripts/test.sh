#!/usr/bin/env bash

SCRIPT="$(realpath "$0")"
DIR=${SCRIPT%/*}
TESTDIR=$HOME/Downloads/$(date +'bookstand-%F-%H-%M')

while true; do
  case $1 in
  -o | --out) shift && TESTDIR="$1" || die ;;
  -f | --from) shift && ANNOTATIONS_FILE="$1" || die ;;
  esac
  shift || break
done

echo $TESTDIR
# while(($#)) ; do
#     echo "The 1st arg is: ==$1=="
#     shift
# done

ANNOTATIONS_FILE=${ANNOTATIONS_FILE:-$1}

REMOTE_URL=$(git -C $DIR config --local --get remote.origin.url)

if [[ -z $ANNOTATIONS_FILE ]]; then
  ANNOTATIONS_FILE=$(mktemp)
  curl -s -o $ANNOTATIONS_FILE https://raw.githubusercontent.com/nntrn/bookstand/assets/annotations.json
fi

# build data files
$DIR/build.sh --books --out $TESTDIR/docs $ANNOTATIONS_FILE
$DIR/build.sh --genre --out $TESTDIR/docs $ANNOTATIONS_FILE
$DIR/build.sh --activity --out $TESTDIR/docs $ANNOTATIONS_FILE
$DIR/build.sh --store --out $TESTDIR/docs $ANNOTATIONS_FILE

# build collections
$DIR/build.sh --tags --out $TESTDIR/docs $ANNOTATIONS_FILE
$DIR/build.sh --annotations --out $TESTDIR/docs $ANNOTATIONS_FILE

[[ ! -d $TESTDIR/assets ]] && git -C $TESTDIR clone --depth 1 -b assets $REMOTE_URL assets

$DIR/build.sh --force --book-covers --out $TESTDIR/assets $ANNOTATIONS_FILE

# $DIR/build.sh --all-data-tasks --all-file-tasks --out $TESTDIR $ANNOTATIONS_FILE
# $DIR/build.sh --book-covers --out $TESTDIR-all $ANNOTATIONS_FILE
