# bookstand

## queryibooks

```sh
queryibooks >annotations.json
```

## ibooktomd

Build jekyll files

```sh
# create page
./ibooktomd.sh --out docs annotations.json
```


## getbookcover

Get book cover

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
