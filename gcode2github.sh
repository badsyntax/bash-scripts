#!/usr/bin/env bash
# Converts a google code subversion repo to a github git repo.
# Allows for author mapping.

echo -n "Google Code SVN URL, eg http://REPO_NAME.googlecode.com/svn/: "
read svn_repo

echo -n "Github URL, eg git@github.com:GITHUB_USERNAME/REPO_NAME.git: "
read git_repo

echo -n "Local project directory: "
read dirname

if [ -z "$svn_repo" ] || [ -z "$git_repo" ] || [ -z "$dirname" ]; then
	echo "Error"
	exit
fi

git svn clone -s "$svn_repo" "$dirname" --no-metadata
	
cd "$dirname"

replace="y"

while [[ $replace == "y" ]]; do

	authors=$(git log --format='- %aE' | sort -u)
	echo "Authors: "
	echo "$authors"

	echo -n "Replace author? y/n: "
	read replace

	if [ "$replace" != "y" ]; then
		continue
	fi

	echo -n "Find author email: "
	read match_email

	echo -n "Replace with author email: "
	read replace_email

	echo -n "Replace with author name: "
	read replace_name

	if [ -n "$match_email" ] && [ -n "$replace_email" ] && [ -n "$replace_name" ]; then
		git filter-branch -f --env-filter '

		an="$GIT_AUTHOR_NAME"
		am="$GIT_AUTHOR_EMAIL"
		cn="$GIT_COMMITTER_NAME"
		cm="$GIT_COMMITTER_EMAIL"

		if [ "$GIT_COMMITTER_EMAIL" = "'"$match_email"'" ]
		then
		    cn="'"$replace_name"'"
		    cm="'"$replace_email"'"
		fi
		if [ "$GIT_AUTHOR_EMAIL" = "'"$match_email"'" ]
		then
		    an="'"$replace_name"'"
		    am="'"$replace_email"'"
		fi

		export GIT_AUTHOR_NAME="$an"
		export GIT_AUTHOR_EMAIL="$am"
		export GIT_COMMITTER_NAME="$cn"
		export GIT_COMMITTER_EMAIL="$cm"
		'
	else
		echo "Error"
	fi
done

echo -n "Pushing to remote github branch..."

git remote add origin "$git_repo" > /dev/null 2>&1

git push origin master > /dev/null 2>&1

if [[ $? == 0 ]]; then
	echo "done."
else
	echo "failed."
	exit
fi
