#!/bin/sh

set -e

function check_file () {
    if [ -e "$1" ] ; then
        echo "File $1 exists"
        exit 1
    fi
}

outfile=result.json

mkdir -p qlbuild
cd qlbuild

if [ ! -r quicklisp.lisp ] ; then
    curl -o quicklisp.lisp https://beta.quicklisp.org/quicklisp.lisp
fi
if [ ! -d quicklisp ] ; then
    sbcl --no-userinit \
         --non-interactive \
         --quit \
         --load quicklisp.lisp \
         --eval '(quicklisp-quickstart:install :path "quicklisp/")'

    tar cf - quicklisp | gzip -9 > ../../ql.tar.gz
fi

if [ ! -d McCLIM ] ; then
    git clone https://github.com/McCLIM/McCLIM
    ln -s ../../McCLIM quicklisp/local-projects
fi
if [ ! -d maxima-code ] ; then
#    git clone https://git.code.sf.net/p/maxima/code maxima-code
    git clone ../../../maxima-code
    (
        cd maxima-code
        ./bootstrap
        ./configure --enable-sbcl
        make
    )
    ln -s ../../maxima-code quicklisp/local-projects
fi
if [ ! -d maxima-client ] ; then
    git clone https://github.com/lokedhs/maxima-client
    ln -s ../../maxima-client quicklisp/local-projects
fi

sbcl --no-userinit \
     --non-interactive \
     --quit \
     --load quicklisp/setup.lisp \
     --load ../init.lisp \
     --eval '(load-system)'

ls quicklisp/dists/quicklisp/software > files

rm -f "$outfile"

for file in `cat files` ; do
    grep "$file" quicklisp/dists/quicklisp/releases.txt | while read rel ; do
        url=`echo $rel | awk '{print $2}'`
        filename=`basename "$url"`
        if [ ! -r "$filename" ] ; then
            wget "$url"
        fi
        checksum=`sha256sum "$filename" | awk '{print $1}'`
        echo '                { "type": "file", "url": "'$url'", "sha256": "'$checksum'" },' >> $outfile
    done
done
