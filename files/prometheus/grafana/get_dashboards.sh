#!/bin/bash

grafana_url="http://admin:admin@grafana-reverse-proxy"
DSDIR=./dashboards

mkdir -p $DSDIR 

all_dashes=$(curl $grafana_url/api/search| jq '.[].uid' -r)

for uid in $all_dashes; do
    echo $uid
    curl $grafana_url/api/dashboards/uid/$uid | jq . > $DSDIR/$uid.json
    yq eval -P $DSDIR/$uid.json > $DSDIR/$uid.yml
done
