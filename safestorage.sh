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
	export SAFESTORAGE_DB=$1
}

function searchSafeStorage()
{
	if [ -f "$SAFESTORAGE_DB" ]; then
		gpg -o - --quiet --yes --decrypt "$SAFESTORAGE_DB" | grep "$1"
	fi

	return 0
}

function writeSafeStorage()
{
	trap "" SIGINT

	TEMP_FILE=`mktemp --quiet --tmpdir=./`
	if [ ! -f "$TEMP_FILE" ]; then
		echo "Error creating temporary file" >&2
		trap - SIGINT
		return 1
	fi

	if [ -f "$SAFESTORAGE_DB" ]; then

		gpg -o "$TEMP_FILE" --quiet --yes --decrypt "$SAFESTORAGE_DB"
		if [ $? -ne 0 ]; then
			echo "Error decrypting SafeStorage DB $SAFESTORAGE_DB" >&2
			rm -f "$TEMP_FILE"
			trap - SIGINT
			return 1
		fi

	fi

	echo "$1" >> "$TEMP_FILE"

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
