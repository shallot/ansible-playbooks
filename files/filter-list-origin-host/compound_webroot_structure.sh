#!/bin/sh -e

dir=$1
link_globs=$2

# Change directory, so path stays relative
cd $dir

for glob in $link_globs; do

  list_files=$(find . -type f -wholename "*/$glob/*")

  # Create links to subdirectories and remove existing regular files
  for file in $list_files; do
    filename=$(basename $file)

    if [ -f ./$filename ]; then
      rm -v ./$filename
    fi

    ln -v -s $file ./$filename
  done

done
