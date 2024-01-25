#!/usr/bin/env bash
# Push changes to annotations.json
#   $ cd ~/bin
#   $ ln -s /path/to/update.sh update-bookstand.sh
#   $ update-bookstand.sh

set -e
SCRIPT=$(realpath $0)
DIR=${SCRIPT%/*}
COMMIT_SCRIPT=$DIR/commit.sh

cd $DIR
open -a Books
sleep 15
queryibooks >annotations.json

[[ $(git ls-files -m annotations.json) ]] && $COMMIT_SCRIPT && git push

osascript -e 'quit app "Books"'
