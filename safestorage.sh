#!/usr/bin/env bash

# Andre Augusto Giannotti Scota (https://sites.google.com/view/a2gs/)

# Script exit if a command fails:
#set -e

# Script exit if a referenced variable is not declared:
#set -u

# If one command in a pipeline fails, its exit code will be returned as the result of the whole pipeline:
#set -o pipefail

# Activate tracing:
#set -x

export SAFESTORAGE_DB=''

function setSafeStorageDB()
{
	if [ "$#" -eq 0 ];
	then
		echo -e "Usage:\n\t$FUNCNAME [YOUR_ENCRYPTED_DATABASE_FILE]"
		return 1
	fi

	export SAFESTORAGE_DB="$1"
	return 0
}

function searchSafeStorage()
{
	if [ -z "$SAFESTORAGE_DB" ]; then
		echo -e "SafeStorage database not set. Run:\n\tsetSafeStorageDB [YOUR_ENCRYPTED_DATABASE_FILE]."
		return 1
	fi

	if [ -f "$SAFESTORAGE_DB" ]; then
		# openssl aes-256-cbc -d -a -in secrets.txt.enc -out secrets.txt.new
		DECTEXT=`gpg -o - --quiet --yes --decrypt "$SAFESTORAGE_DB"`
		if [ $? -ne 0 ]; then
			echo "Error decrypting SafeStorage DB $SAFESTORAGE_DB" >&2
			return 1
		fi

		echo "$DECTEXT" | grep "$1"
		unset DECTEXT
	fi

	return 0
}

function writeSafeStorage()
{
	if [ -z "$SAFESTORAGE_DB" ]; then
		echo -e "SafeStorage database not set. Run:\n\tsetSafeStorageDB [YOUR_ENCRYPTED_DATABASE_FILE]."
		return 1
	fi

	trap "" SIGINT

	if [ -f "$SAFESTORAGE_DB" ]; then
		
		TEMP_FILE="$SAFESTORAGE_DB".tmp

		# openssl aes-256-cbc -d -a -in secrets.txt.enc -out secrets.txt.new
		gpg -o "$TEMP_FILE" --quiet --yes --decrypt "$SAFESTORAGE_DB"
		if [ $? -ne 0 ]; then
			echo "Error decrypting SafeStorage DB $SAFESTORAGE_DB" >&2
			rm -f "$TEMP_FILE"
			trap - SIGINT
			return 1
		fi

		echo "$1" >> "$TEMP_FILE"
	else
		TEMP_FILE="$SAFESTORAGE_DB".tmp
		echo "$1" > "$TEMP_FILE"
	fi

	# openssl aes-256-cbc -a -salt -in secrets.txt -out secrets.txt.enc
	gpg -o "$SAFESTORAGE_DB" --quiet --yes --armor --symmetric --cipher-algo AES256 "$TEMP_FILE"
	if [ $? -ne 0 ]; then
		echo "Error encrypting SafeStorage DB $SAFESTORAGE_DB" >&2
		rm -f "$TEMP_FILE"
		trap - SIGINT
		return 1
	fi

	rm -f "$TEMP_FILE"
	trap - SIGINT

	return 0
}

if [ "$0" = "$BASH_SOURCE" ]; then

	echo -e "SafeStorage shell functions didnt load. Usage:\n\tsource $0"
	exit 1

else

	echo "SafeStorage shell functions loaded. Define your encrypted database:"
	echo -e "\tsetSafeStorageDB [YOUR_ENCRYPTED_DATABASE_FILE]"
	echo -e "\t\tYOUR_ENCRYPTED_DATABASE_FILE mandatory. Will be created if not exists."
	echo
	echo "Then you are able to call writeSafeStorage and searchSafeStorage functions."

	return 0

fi
