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
download_message=$(wget https://storage.googleapis.com/$src.tar.gz \
  -O $download_dir/$project.tar.gz 2>&1) || { echo "$download_message" >&2; exit 1; }

tar zxvf $download_dir/$project.tar.gz -C $extract_dir/ \
  --strip-components=$filter_len $filter


# The "modified" and "version" strings in the filter list headers change every
# 10min which prevents any kind of caching. Replacing the values with fixtures
# allows to test how much traffic reduction caching could bring.
filterlist_modification_start=$(date +%s)

# Convert fixtures to required format
fixture_time='20230329 09:00:00 UTC'
fixture_modified=$(date -d "$fixture_time" '+%d %b %Y %H:%M %Z')
fixture_version=$(date -d "$fixture_time" '+%Y%m%d%H%M')

# Find all txt files in the "default" directory
filterlist_files=$(find $extract_dir/default/ -type f -name "*.txt")

## Loop through each file
for filterlist_file in $filterlist_files
do
  # Check if the file contains the lines "! Last modified: <timestamp>" and "Version: <timestamp>"
  if [ "$(grep -c "! Last modified: " $filterlist_file)" -ne 0 ] && [ "$(grep -c "Version: " $filterlist_file;)" -ne 0 ]; then
    # Replace timestamps with fixture
    echo "$filterlist_file: Setting version string to $fixture_modified and last modified to $fixture_modified"
    sed -i "s/! Version: .*$/! Version: $fixture_version/g" $filterlist_file
    sed -i "s/! Last modified: .*$/! Last modified: $fixture_modified/g" $filterlist_file

    # Remove old brotli file and regenerate the new version
    rm -f $filterlist_file.br
    brotli --quality 9 --force --output $filterlist_file.br --input $filterlist_file --verbose

    # Remove old gz file as it gets otherwise updated and regenerate the new version
    rm -f $filterlist_file.gz
    7za a -tgzip -mx=9 -bd -mpass=5 $filterlist_file.gz $filterlist_file
  fi
done
echo "Filterlists header modification runtime: $(($(date +%s)-filterlist_modification_start))s"


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
    git clone $manifest.git $input/$manifest_short
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
