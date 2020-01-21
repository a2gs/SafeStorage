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
		gpg -o - -q --yes --decrypt "$SAFESTORAGE_DB" | grep $1
	fi
}

function writeSafeStorage()
{
	trap "" SIGINT

	TEMP_FILE=`mktemp --quiet --tmpdir=./`

	if [ -f "$SAFESTORAGE_DB" ]; then
		gpg -o "$TEMP_FILE" -q --yes --decrypt "$SAFESTORAGE_DB" | grep $1
	fi

	echo "$1" >> "$TEMP_FILE"

	gpg -o "$SAFESTORAGE_DB" -q --yes --symmetric --cipher-algo AES256 "$TEMP_FILE"

	rm -f "$TEMP_FILE"

	trap - SIGINT
}
