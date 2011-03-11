#!/usr/bin/env bash
# Generate a public SSH key and upload to remote host for password-less login. 

function error {
	echo "Error!"
	exit
}

echo -n "Remote host: "
read host

echo -n "Remote username: "
read username

if [ -z "$host" ] || [ -z "$username" ]; then
	error
fi

if [ -f ~/.ssh/id_rsa.pub ]; then
	echo -n "~/.ssh/id_rsa.pub exists! Do you want to use the existing key? (y/n) "
	read existing_key
fi

if [ -z "$existing_key" ] || [ "$existing_key" == "n" ]; then

	echo -n "Your email: "
	read email

	if [ -z "$email" ]; then
		error
	fi

	ssh-keygen -t rsa -C "$email"
fi

cat ~/.ssh/id_rsa.pub | ssh -l "$username" "$host" 'cat >> ~/.ssh/authorized_keys'
