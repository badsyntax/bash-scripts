#!/usr/bin/env bash

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "Usage: ./closurecompiler file.js file.min.js"
	exit
fi

if [ ! -f "$1" ]; then
	echo "File does not exist!"
	exit
fi

if [ -f "$2" ]; then
	echo -n "Min file already exists! Overwrite? (y/n): "
	read OVERWRITE
	if [ "$OVERWRITE" != "y" ]; then
		echo "Goodbye!"
		exit 1
	fi
fi

curl \
	-s \
	-d compilation_level=SIMPLE_OPTIMIZATIONS \
	-d output_format=text \
	-d output_info=compiled_code \
	--data-urlencode "js_code@${1}" \
	http://closure-compiler.appspot.com/compile \
	> "$2"

# Here we'll trim the contents of the output file and get the 
# total bytes to determine if the code was successfully compiled.
BYTES=$(\
	cat test.min.js | \
	tr -d "\n" | tr -d " " | tr -d "\t" | \
	wc -c | \
	tr -d " " )

if [ "$BYTES" -gt 0 ]; then
	echo "Done."
	exit 0
else
	echo "Error: 0 byte filesize detected. This is likely due to a Javascript error. Please check your code and try again."
	exit 1
fi
