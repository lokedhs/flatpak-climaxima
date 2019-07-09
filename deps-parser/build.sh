#!/bin/sh

set -e

releases=$HOME/quicklisp/dists/quicklisp/releases.txt
outfile=result.json

if [ -r "$outfile" ] ; then
    echo "$outfile already exists"
    exit 1
fi

for file in `cat files` ; do
    grep "$file" "$releases" | while read rel ; do
        url=`echo $rel | awk '{print $2}'`
        filename=`basename "$url"`
        if [ ! -r "$filename" ] ; then
            wget "$url"
        fi
        checksum=`sha256sum "$filename" | awk '{print $1}'`
        echo '                { "type": "file", "url": "'$url'", "sha256": "'$checksum'" },' >> $outfile
    done
done
