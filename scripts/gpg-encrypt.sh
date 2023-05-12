#!/bin/sh

# Usage: ./gpg-encrypt INPUT_PATH OUTPUT_PATH SECRET_PASSPHRASE
# e.g. ./scripts/gpg-encrypt.sh `pwd`/terraform/env/dev/certs `pwd`/terraform/env/dev/config/certs password

INPUT_PATH=$1
OUTPUT_PATH=$2
SECRET_PASSPHRASE=$3

/usr/bin/mkdir -p $OUTPUT_PATH

# Encrypt the files

for file in $INPUT_PATH/*
do
    FILE_NAME="$(/usr/bin/basename -- $file)"
    
    /usr/bin/gpg --cipher-algo AES256 --quiet --batch --yes --passphrase="$SECRET_PASSPHRASE" \
    --output $OUTPUT_PATH/${FILE_NAME}.enc --symmetric $file
done