#!/bin/sh -e

savelog -c {{ filter_list_origin_save_logs }} -qnl {{ filter_list_origin_logs }}/subscription_output
savelog -c {{ filter_list_origin_save_logs }} -qnl {{ filter_list_origin_logs }}/subscription_errors

# TODO: integrate the logging into the script itself
# https://gitlab.com/eyeo/devops/legacy/sitescripts/-/issues/18
exec env PYTHONPATH=/opt/sitescripts \
  python -u -m sitescripts.subscriptions.bin.updateSubscriptionDownloads \
  3>&1 1>{{ filter_list_origin_logs }}/subscription_output 2>&3 \
  | perl -pe 'BEGIN { $| = 1; } s/^/"[" . scalar localtime() . "] "/e' \
  >> {{ filter_list_origin_logs }}/subscription_errors
