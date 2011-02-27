!/usr/bin/env bash
#
# simple recursive search and replace string in files
# setup: alias replace='~/replace.sh'
# notes: you will need to escape special chars! eg: replace '\/dir1' '\/dir2' .
# usage: replace <oldstring> <newstring> <path> <depth>
# examples: 
# replace "([^\s]+.php)" "\/\1" .
# replace "\"\/([^\/]+.php)" "\"\/dir\/\1" .

if [ ! -n "$1" ] || [ ! -n "$2" ] || [ ! -n "$3" ]; then

	echo "Usage: replace.sh OLDSTRING NEWSTRING PATH"

	exit;
fi

[ -n "$4" ] && maxdepth=$4 || maxdepth=9999

find "$3" -maxdepth "$maxdepth" -type f -exec perl -pi -e "s/$1/$2/g" '{}' \;
