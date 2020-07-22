#!/bin/sh -e

if [ ! -d "$1" ]; then
  echo "$1 not a directory, aiee" >&2
  exit 1
fi
input="$1"

if [ ! -d "$2" ]; then
  echo "$2 not a directory, aiee" >&2
  exit 1
fi
output="$2"

for filename in $(find $input -maxdepth 1 -type f ! -name '*.gz'); do
  7za a -tgzip -y -mx=9 -bd -mpass=5 "$output/$(basename $filename).gz" "$filename"
done
