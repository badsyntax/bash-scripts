#!/usr/bin/env bash
#mp3arrange.sh by badsyntax.co

#- This bash script will re-arrange an iTunes collection 
#  from format 'Artist/Album/Track.mp3' to format 'Genre/Artist/Album/Track.mp3'.
#- Only mp3 files are moved.
#- The folder data is collected from the track ID3 V2 tags. 
#- The id3v2 utility is required.


# Constants
VERSION="0.1.0"

# DEFAULTS
BASE_DIR="."
TARGET_DIR="."
TOTAL_SIZE="0"
TOTAL_FILES="0"
MOVE_ERRORS="0"

usage()
{
	less << EOF
DESCRIPTION
	Arrange folders and files by MP3 ID3 type.

USAGE
	mp3arrange.sh [<directory>]

OPTIONS
	-h, --help	Show this help
	-l, --log	Log errors and general stats
	--version	Print current script version

DIRECTORY
	If no directory is specified, the current directory will be used.

EXAMPLES
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
	DIR=$(echo "$1" | sed 's/[\/\\=+\<\>]/-/g')
	
	if [ "$DIR" == "" ]
	then
		DIR=$2
	fi

	echo "$DIR"
}


move_files()
{
	find "Music" -type f -iname "*.mp3" | while read file
	do
		echo "Processing $file..."

		INFO=$( id3v2 -l "$file" )

		GENRE_DIR=$( safe_dirname "`echo "$INFO" | sed -n '/^TCON/s/^.*: //p' | sed 's/ (.*//'`" "Unknown Genre")

		ARTIST_DIR=$( safe_dirname "`echo "$INFO" | sed -n '/^TPE1/s/^.*: //p' | sed 's/ (.*//'`" "Uknown Artist")

		ALBUM_DIR=$( safe_dirname "`echo "$INFO" | sed -n '/^TALB/s/^.*: //p' | sed 's/ (.*//'`" "Uknown Album")
	
		#TODO: add default values if non found

		DIRECTORY="$BASE_DIR/$GENRE_DIR/$ARTIST_DIR/$ALBUM_DIR"

		mkdir -p "$DIRECTORY" > /dev/null 2>&1 
		if_error "Could not create directory \"$DIRECTORY\"" 1

		mv "$file" "$DIRECTORY/" > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			echo "Could not move file \"$file\""
			MOVE_ERRORS=$(($MOVE_ERRORS+1))
			echo "$MOVE_ERRORS errors"
		fi
	done

	echo "$MOVE_ERRORS errors"
	exit
}

#TODO: not ignoring hidden files
remove_empty_directories()
{
	EMPTY_DIRECTORIES=$(find . -type d -empty | wc -l | tr -d " ")
	if [ "$EMPTY_DIRECTORIES" -gt 0 ]
	then
		echo -e "\nThere are $EMPTY_DIRECTORIES empty direcories in the base directory \"$BASE_DIR\"."
		echo -n "Do you want to remove the empty directories? (y/n) "
		read remove_dirs
	
		if [ "$remove_dirs" == "y" ] || [ "$remove_dirs" == "y" ]
		then	
			echo -n "Removing directories, please wait..."
		
			find "$BASE_DIR" -depth -type d -empty -exec rmdir {} \;

			echo "done."
		fi
	fi
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

	echo "$MOVE_ERRORS errors encountered."
			
	remove_empty_directories

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
