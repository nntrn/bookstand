# bookstand

## queryibooks

```sh
queryibooks >annotations.json
```

## ibooktomd

Build markdown file for annotations

```sh
# create page
./ibooktomd.sh --out docs/ibooks annotations.json

# create post
SLUGDATE=1 ./ibooktomd.sh --out _posts annotations.json
```

```console
$ tree _posts
_posts
├── 2012-10-26-monoculture.md
├── 2017-03-31-the-mastery-of-love.md
├── 2021-07-28-the-art-of-war.md
└── 2023-08-31-the-socrates-express.md

$ tree docs/ibooks
docs/ibooks
├── monoculture.md
├── the-mastery-of-love.md
├── the-art-of-war.md
└── the-socrates-express.md
```

## getbookcover

Get book cover

```sh
# get asset ids
IDS=($(jq -r 'map(.ZASSETID)|unique|join("\n")' annotations.json))
# or
# IDS=(1001812902 1006365439 1018802008 1023327825)

# get cover for multiple books
./getbookcover.sh --out path/to/dir --min-width 600 ${IDS[@]}

# run for single book
./getbookcover.sh 1483501679

# pass json file instead of ids
./getbookcover.sh --get-assetid annotations.json
```

Default:
* `--out`: docs/assets/artwork
* `--min-width`: 200


## jekyll

```sh
cd docs
bundle install
bundle exec jekyll serve
```
