#!/bin/bash

script_name=$1
log_path=$2
kill $(cat $log_path/$script_name.pid)
rm $log_path/$script_name.pid