#!/bin/sh
cd {{ filter_list_origin_inputs }}/
for i in $(ls)
do
  if [ -d $i/.hg ]; then
    hg pull -R $i
    hg update -R $i -r default --check
  elif [ -d $i/.git ]; then
    git -C $i pull
  else
    echo "$i is not a version control repository, assuming it has a separate update method"
    #echo "aiee, what is $i? neither hg nor git" >&2
    #ls -l $i >&2
  fi
done
