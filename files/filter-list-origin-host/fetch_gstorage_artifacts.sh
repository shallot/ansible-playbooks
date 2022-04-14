#!/bin/sh -e

test -d "$1" || mkdir "$1"
input="$1"

test -d "$2" || mkdir "$2"
output="$2"

src=$3

filter="$4"
filter_len=$(echo "$filter" | tr "/" "\n" | wc -w)

diff_retention=$5

project=$(basename $input)
fetch_dir=$input/${project}.fetched
test -d $fetch_dir || mkdir $fetch_dir

curl -sS -L https://storage.googleapis.com/$src.tar.gz | \
  tar zxvf - -C $fetch_dir --strip-components=$filter_len $filter

if [ -e $fetch_dir/index.json ]; then
  if ! cat $fetch_dir/index.json | jq .; then
    echo "jq failed on $fetch_dir/index.json, with error code $?"
    exit 1
  fi
fi

if [ $diff_retention ]; then
  find $fetch_dir/diff -type f -mtime +$diff_retention -delete -print
fi

rsync -v -aHAX --delete $fetch_dir/* $output
