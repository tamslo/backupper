#!/bin/bash

script_name=$1
log_path=$2
timestamp=$(date +"%y-%m-%d")
dart $script_name.dart \
    2>&1 >> $log_path/${timestamp}_backup.log &
echo $! > $log_path/$script_name.pid
tail -f $log_path/${timestamp}_backup.log
