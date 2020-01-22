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
	export SAFESTORAGE_DB="$1"
}

function searchSafeStorage()
{
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
	gpg -o "$SAFESTORAGE_DB" --quiet --yes --symmetric --cipher-algo AES256 "$TEMP_FILE"
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
