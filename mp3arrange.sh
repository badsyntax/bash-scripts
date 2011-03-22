#!/usr/bin/env bash
#filename: mp3arrange.mp3
#developer: badsyntax.co


#
# Constants
#
VERSION="0.1.0"

#
# DEFAULTS
#
BASE_DIR="."
TARGET_DIR="."
TOTAL_SIZE="0"
TOTAL_FILES="0"

usage()
{
	less << EOF
DESCRIPTION
	Arrange folders and files by MP3 ID3 type.

USAGE
	mp3arrange.sh [<options>] [<directory>]

OPTIONS
	-h, --help	Show this help
	-l, --log	Log errors and general stats
	--version	Print current script version

DIRECTORY
	If no directory is specified, the current directory will be used.

EXAMPLES
	./mp3arrange.sh -l .
	./mp3arrange.sh /home/user/Music/

VERSION
	$VERSION
EOF
	exit 0
}

#TODO check perms on base & target folder
check_dependencies()
{
	type -P id3v2 &>/dev/null ||
	{
		echo "id3v2 utility not found! Exiting." >&2
		exit 1
	}
}

if_error()
{
	if [ $? -ne 0 ]
	then
		echo "$1" 
		[ -n "$2" ] && { echo "Exiting."; exit $2; }
	fi
}

safe_dirname()
{
	echo "$1" | sed 's/[\/\\=+\<\>]/-/g'
}

function get_stats()
{
	TOTAL_FILES=$( find "$BASE_DIR"  -type f -iname "*.mp3" | wc -l | tr -d " " )

	TOTAL_SIZE=$( find "$BASE_DIR" -type f -iname "*.mp3" -ls | awk '{ print $7 }' | awk '{ total += $1 } END { print total }' )

	if [ "$TOTAL_SIZE" -ge "1073741824" ]
	then
		TOTAL_SIZE="$((TOTAL_SIZE / 1073741824))G"

	elif [ "$TOTAL_SIZE" -ge "1048576" ]
	then
		TOTAL_SIZE="$((TOTAL_SIZE / 1048576))M"
	else
		TOTAL_SIZE="$((TOTAL_SIZE / 128))K"
	fi
}

#TODO: total file errors
move_files()
{
	find "$BASE_DIR" -type f -iname "*.mp3" | while read file
	do
		echo "Processing $file..."

		GENRE_DIR=$( safe_dirname "`id3v2 -l "$file" | sed -n '/^TCON/s/^.*: //p' | sed 's/ (.*//'`" )

		ARTIST_DIR=$( safe_dirname "`id3v2 -l "$file" | sed -n '/^TPE1/s/^.*: //p' | sed 's/ (.*//'`" )

		ALBUM_DIR=$( safe_dirname "`id3v2 -l "$file" | sed -n '/^TALB/s/^.*: //p' | sed 's/ (.*//'`" )

		DIRECTORY="$BASE_DIR/$GENRE_DIR/$ARTIST_DIR/$ALBUM_DIR"

		mkdir -p "$DIRECTORY" > /dev/null 2>&1 
		if_error "Could not create directory \"$DIRECTORY\"" 1

		mv "$file" "$DIRECTORY/" > /dev/null 2>&1
		if_error "Could not move file \"$file\""
	done
}

remove_empty_directories()
{
	#TODO: not ignoring hidden files
	find "$BASE_DIR" -depth -type d -empty -exec rmdir {} \;
}

main()
{
	check_dependencies
	
	TARGET_DIR="$BASE_DIR"
	
	echo -n "Finding MP3's, please wait..."

	get_stats
	
	echo "done."

	if [ "$TOTAL_FILES" -eq 0 ]
	then
		echo "No MP3's found!"
		exit 1
	fi

	echo -e "Total files:\t$TOTAL_FILES"
	echo -e "Total size:\t$TOTAL_SIZE"
	echo -e "Base dir:\t$BASE_DIR"
	echo -e "Target dir:\t$TARGET_DIR"

	echo -en "\nDo you want to continue? (y/n) "
	read cont

	if [ "$cont" != "y" ] && [ "$cont" != "Y" ]
	then
		echo "Goodbye."
		exit 0
	fi

	move_files

	EMPTY_DIRECTORIES=$(find . -type d -empty | wc -l | tr -d " ")
	if [ "$EMPTY_DIRECTORIES" -gt 0 ]
	then
		echo -e "\nThere are $EMPTY_DIRECTORIES empty direcories in the base directory \"$BASE_DIR\"."
		echo -n "Do you want to remove the empty directories? (y/n) "
		read remove_dirs
	
		if [ "$remove_dirs" == "y" ] || [ "$remove_dirs" == "y" ]
		then	
			echo -n "Removing directories, please wait..."
		
			remove_empty_directories

			echo "done."
		fi
	fi

	echo "All done!"
	exit 0
}

# Parse parameters
while test $# != 0
do
	case "$1" in
		-h|--help)
			usage
			;;
		--version)
			echo "Version $VERSION"
			exit 0
			;;
		*)
			[ -n "$1" ] && BASE_DIR="$1"
			
			if [ ! -d "$BASE_DIR" ]
			then
				echo "Invalid directory!"
				exit 0
			fi
			;;
	esac
	shift
done
main
