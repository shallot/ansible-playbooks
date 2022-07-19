#!/bin/sh -e

test -d "$1" || mkdir "$1"

input="$1"

download_dir="$1/downloaded"
test -d "$download_dir" || mkdir "$download_dir"

extract_dir="$1/extracted"
test -d "$extract_dir" || mkdir "$extract_dir"

test -d "$2" || mkdir "$2"
output="$2"

src=$3

filter="$4"
filter_len=$(echo "$filter" | tr "/" "\n" | wc -w)

diff_retention=$5

manifest=$6
manifest_short=$(basename $manifest)

includes=$7

project=$(basename $input)
fetch_dir=$input/${project}.fetched
test -d $fetch_dir || mkdir $fetch_dir

# Disable progress bar with --no-verbose basic information still
# gets printed out
wget --no-verbose https://storage.googleapis.com/$src.tar.gz \
  -O $download_dir/$project.tar.gz && \
  tar zxvf $download_dir/$project.tar.gz -C $extract_dir/ \
  --strip-components=$filter_len $filter

# Only the v3 subdirectory has a index.json in it right now.
for index_file in $(find $extract_dir -type f -name index.json); do
  if ! cat $index_file | jq .; then
    echo "jq failed on $index_file, with error code $?"
    exit 1
  fi
done

# Pull manifest, if defined, and run sanity check
if [ ! -z $manifest ]; then
  if [ ! -d $input/$manifest_short ]; then
    git clone $manifest $input/$manifest_short
  fi

  git -C $input/$manifest_short pull --ff-only

  if ! $input/$manifest_short/src/manifest_sanity_check.sh \
    $extract_dir $input/$manifest_short/manifest.json; then
    echo "sanity check failed with error code $?."
    exit 2
  fi
fi

# Copy defined includes to fetch dir
echo $includes | rsync -v -aHAX --include-from=- \
  --exclude "*" $extract_dir/ $fetch_dir

if [ $diff_retention ]; then
  # Only the v3 subdirectory has diff lists in it.
  # It makes it a niche use case, but this simple implementation should suffice.
  find $fetch_dir -wholename "*/diff/*" -type f -mtime +$diff_retention -delete -print
fi

rsync -v -aHAX --delete $fetch_dir/ $output
