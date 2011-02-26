#!/usr/bin/env bash

in=$1
out=$2

if [ -z "$in" ] || [ -z "$out" ]; then
	echo "Usage: ./closurecompiler file.js file.min.js"
	exit
fi

if [[ ! -f "$in" ]]; then
	echo "File does not exist!"
	exit
fi

curl -s \
        -d compilation_level=SIMPLE_OPTIMIZATIONS \
        -d output_format=text \
        -d output_info=compiled_code \
        --data-urlencode "js_code@${in}" \
        http://closure-compiler.appspot.com/compile \
        > "$out"

echo "done."
