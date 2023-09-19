# bookstand

## queryibooks

```sh
queryibooks >annotations.json
```

Get [queryibooks](https://github.com/nntrn/queryibooks)

## Setup

See how this project is built in [workflows/jekyll-build.yml](.github/workflows/jekyll-build.yml)

```console
$ git clone https://github.com/nntrn/bookstand.git
$ cd bookstand

$ ./scripts/build.sh --all-data-tasks --all-file-tasks --out ./docs
$ ./scripts/start.sh
```

## Build

```
./build.sh - script for building jekyll files for @nntrn/bookstank

USAGE
  $ ./build.sh [OPTIONS] [TASKS] [<ids>...] [file]

OPTIONS
  -h, --help
  -f, --force
  -o, --out <DIR>         Directory to write files to (default: $OUTDIR)
  -w, --width <PIXELS>    Set image width for --book-cover task

TASKS
  --books
  --genre               Create $OUTDIR/_data/genre.json
  --activity            Create $OUTDIR/_data/activity.json
  --tags                Create files in $OUTDIR/_tags
  --annotations         Create files in $OUTDIR/_annotations
  --book-cover          Run task to get book cover
  --all                 Run all tasks
  --all-data-tasks      Same as --book --genre --activity
  --all-file-tasks      Same as --tag and --annotation
```

### Data files

- Create `_data/activity.json`

  ```sh
  ./build.sh --activity annotations.json
  ```

- Create `_data/genres.json`

  ```sh
  ./build.sh --genre annotations.json
  ```

- Create `_data/books.json`
  ```sh
  ./build.sh --books annotations.json
  ```

### Collections

- Build files for `_tags`

  ```sh
  ./build.sh --tags tags.json
  ```

- Build files for `_annotations`
  ```sh
  ./build.sh --activity annotations.json
  ```

### Book covers

- WIP

  ```sh
  # get all
  ./build.sh --book-covers annotations.json

  # or get few
  ./build.sh --book-covers 1006365439 1018802008 1023327825

  # or get one
  ./build.sh --book-covers 1006365439
  ```

- getbookcover.sh

  ```sh
  # pass asset ids
  ./getbookcover.sh -w 150 1483501679
  ./getbookcover.sh -w 150 1001812902 1006365439 1018802008 1023327825

  # pass json file instead of ids
  ./getbookcover.sh -w 150 --get-assetid annotations.json
  ```

## local development

```sh
cd docs
bundle install
bundle exec jekyll serve
```
