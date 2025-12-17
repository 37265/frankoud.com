#!/bin/bash

now = date +"%Y-%m-%d %H:%M:%S"
commit_msg = "$1"

if ! [[e "index.html"]]; then
    echo "index.html not found. Aborting script."
    exit 1
else
    
fi