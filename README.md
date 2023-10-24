# bookstand

## queryibooks

Get [queryibooks](https://github.com/nntrn/queryibooks)

```sh
queryibooks >annotations.json
```

## Build

```console
$ git clone -b staging https://github.com/nntrn/bookstand.git
$ git clone -b assets https://github.com/nntrn/bookstand.git /path/to/bookstand-assets

$ cd bookstand

$ ./scripts/build.sh --all-data-tasks --all-file-tasks  
$ ./scripts/build.sh --book-covers --out /path/to/bookstand-assets

$ jq -s '.' /path/to/bookstand-assets/store/*.json >docs/_data/store.json

$ ./scripts/start.sh
```

See how this project is built in [workflows/jekyll-build.yml](.github/workflows/jekyll-build.yml)
