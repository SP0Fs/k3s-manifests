#!/bin/sh

# Usage ./gpg-encrypt INPUT_PATH SECRET_PASSPHRASE
# e.g. ./scripts/gpg-decrypt.sh `pwd`/terraform/env/dev/config password

INPUT_PATH=$1
SECRET_PASSPHRASE=$2

WORKDIR=$INPUT_PATH/.decrypted

mkdir -p $WORKDIR


# Decrypt the files

for file in $(find $INPUT_PATH -type f -name "*.enc" -exec ls {} \;)
do
    FILE_NAME="$(/usr/bin/basename -- $file)"
    
    /usr/bin/gpg --quiet --batch --yes --decrypt --passphrase="$SECRET_PASSPHRASE" \
    --output $WORKDIR/${FILE_NAME%.*} $file
done
