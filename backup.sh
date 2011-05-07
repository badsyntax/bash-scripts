#!/bin/bash

#first we need to copy our public key to remote host!
#http://troy.jdmz.net/rsync/index.html

# Defaults
TODAY=`date '+%Y-%m-%d'`

SSH_KEY="/home/user/keys/host-rsync-key"
REMOTE_USER="remote.user"
REMOTE_HOST="remote.host"
LOCAL_HOST="$HOSTNAME"
MAILTO="your@email.com"

WWW_DIR="/var/www"
BACKUP_DIR="/srv/backup"

BACKUP_LOCAL_DIR="$BACKUP_DIR/$LOCAL_HOST"
BACKUP_REMOTE_DIR="$BACKUP_DIR/$REMOTE_HOST"

BACKUP_LOCAL_DB_DIR="$BACKUP_DIR/$LOCAL_HOST/db"
BACKUP_REMOTE_DB_DIR="$BACKUP_DIR/$REMOTE_HOST/db"

BACKUP_LOCAL_MYSQL_DB="$BACKUP_LOCAL_DB_DIR/mysqldump.all.gz"
BACKUP_REMOTE_MYSQL_DB="$BACKUP_REMOTE_DB_DIR/mysqldump.all.gz"

BACKUP_LOCAL_PSQL_DB="$BACKUP_LOCAL_DB_DIR/postgresdump.all.gz"
BACKUP_REMOTE_PSQL_DB="$BACKUP_REMOTE_DB_DIR/postgresdump.all.gz"

MYSQL_USERNAME="username"
MYSQL_PASSWORD="password"

if_error()
{
	if [ $? -ne 0 ]
	then
		echo "$1" | mail -s "$LOCAL_HOST backup error!" "$MAILTO"
		[ -n "$2" ] && 
		{ 
			exit $2; 
		}
	fi
}

local_db_to_remote()
{
	mysqldump --opt -u$MYSQL_USERNAME -p$MYSQL_PASSWORD --all-databases | gzip | ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST "cat > $BACKUP_LOCAL_MYSQL_DB"
	if_error "There was an error trying to copy $LOCAL_HOST MySQL databases to $REMOTE_HOST." 1

	pg_dumpall | gzip | ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST "cat > $BACKUP_LOCAL_PSQL_DB"
	if_error "There was an error trying to copy $LOCAL_HOST PostgreSQL databases to $REMOTE_HOST." 1
}

remote_db_to_local()
{
	ssh -i $SSH_KEY $REMOTE_USER@$REMOTE_HOST "mysqldump --opt -u$MYSQL_USERNAME -p$MYSQL_PASSWORD --all-databases | gzip" > "$BACKUP_REMOTE_MYSQL_DB"
	if_error "There was an error trying to copy $REMOTE_HOST databases to $LOCAL_HOST." 1
}

local_sites_to_remote()
{
	rsync -avz -e "ssh -i $SSH_KEY" $WWW_DIR $REMOTE_USER@$REMOTE_HOST:$BACKUP_LOCAL_DIR
	if_error "There was an error trying to rsync site files from $LOCAL_HOST to $REMOTE_HOST." 1
}

remote_sites_to_local()
{
	rsync -avz -e "ssh -i $SSH_KEY" $REMOTE_USER@$REMOTE_HOST:$WWW_DIR $BACKUP_REMOTE_DIR
	if_error "There was an error trying to rsync site files from $REMOTE_HOST to $LOCAL_HOST." 1
}

main()
{
	local_db_to_remote
	remote_db_to_local

	local_sites_to_remote
	remote_sites_to_local

	echo "$LOCAL_HOST backup complete!" | mail -s "${TODAY} $LOCAL_HOST backup complete!" "$LOCAL_HOST"
}
main
