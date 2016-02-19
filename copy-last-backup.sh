#!/bin/bash
#
# Copy a backup from one folder to another.
#
# Author: Francisco Troncoso


### Functions

# Lists the contents of a directory, ordered alphabetically
lsdir() {
  find "$1" -mindepth 1 -maxdepth 1 -type d | sort
}

# Returns the number of directories in a given directory
lsdircount() {
  local list=$(lsdir "$1")
  if [[ ! -z "${list}" ]]; then
    echo "${list}" | wc -l
  else
    echo "0"
  fi
}


### Command line arguments

if [[ "$#" -ne 3 ]]; then
  echo "Usage: $0 <source_folder> <dest_folder> <max_backups_dest>" >&2
  exit 1
fi

# Source folder
readonly SRC_FOLDER="$(realpath "$1")"

# Destination backups folder
readonly DST_FOLDER="$(realpath "$2")"

# Maximum number of simultaneous backups
readonly MAX_BUS="$3"


### MAIN

# *** Copy backup to destination folder
src_bu="$(echo "$(lsdir "${SRC_FOLDER}")" | tail -n 1)"
mkdir -p "${DST_FOLDER}"
cp -al --remove-destination "${src_bu}" "${DST_FOLDER}"

# *** Remove old backups in destination folder
bu_count="$(lsdircount "${DST_FOLDER}")"
if [ "${bu_count}" -gt "${MAX_BUS}" ]; then
  n="$((${bu_count} - ${MAX_BUS}))"
  bus="$(echo "$(lsdir "${BUS_FOLDER}")" | head -n "${n}")"
  echo "${bus}" | xargs rm -r
fi
