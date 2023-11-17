# bookstand

## queryibooks

Get [queryibooks](https://github.com/nntrn/queryibooks)

```sh
queryibooks >annotations.json
```

## Usage

### Build collection files

```sh
# Create files in docs/_tags/*.html
./scripts/build.sh --tags

# Create files in docs/_annotations/*.md
./scripts/build.sh --annotations
```

```sh
./scripts/build.sh --all-file-tasks
```

### Create data files

```sh
# Create docs/_data/books.json
./scripts/build.sh --books

# Create docs/_data/activity.json
./scripts/build.sh --activity

# Create docs/_data/genre.json
./scripts/build.sh --genre

# Create docs/_data/store.json
./scripts/build.sh --store
```

```sh
./scripts/build.sh --all-data-tasks
```

## Build

```sh
git clone -b staging https://github.com/nntrn/bookstand.git
cd bookstand

./scripts/start.sh
./scripts/start.sh --rebuild

./scripts/build.sh --all-data-tasks --all-file-tasks --out ./docs
./scripts/build.sh --book-covers --out /path/to/asset/branch/covers
```

See how this project is built in [workflows/jekyll-build.yml](.github/workflows/jekyll-build.yml)
