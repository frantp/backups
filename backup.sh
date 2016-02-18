#!/bin/bash
#
# Automated incremental backups of a folder.
#
# Author: Francisco Troncoso

# Avoid remote login password:
#    ssh-keygen
#    ssh-copy-id -i ~/.ssh/id_rsa.pub user@host


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

# Returns the last directory in a given directory, alphabetically
lastdir() {
  echo "$(lsdir "$1")" | tail -n 1
}

# Remove the first n directories in a given directory, alphabetically
rmfirstdirs() {
  echo "$(lsdir "$1")" | head -n "$2" | xargs rm -r
}


### Command line arguments

if [[ "$#" -ne 3 ]]; then
  echo "Usage: $0 <source_folder> <backups_folder> <max_backups>" >&2
  exit 1
fi

# Source folder
readonly SRC_FOLDER="$1"
#readonly SRC_FOLDER="$(realpath $1)"

# Destination backups folder
readonly BUS_FOLDER="$2"
#readonly BUS_FOLDER="$(realpath $2)"

# Maximum number of simultaneous backups
readonly MAX_BUS="$3"


### MAIN

# Backup id
readonly BUID="$(date +%Y-%m-%d_%H:%M:%S)"

# Log file
readonly LOG_FILE="${BUID}.log"

# Destination folder for backup
readonly BU="${BUS_FOLDER}/${BUID}"

# *** Ensure folder existence if local
if [[ ! "${BUS_FOLDER}" = *:* ]]; then
  mkdir -p "${BUS_FOLDER}"
fi

# *** Create new backup
link=""
bu_count="$(lsdircount "${BUS_FOLDER}")"
if [[ "${bu_count}" -gt 0 ]]; then  # hardlinked to last backup
  link=" --link-dest=$(lastdir "${BUS_FOLDER}")"
fi
rm -f "${LOG_FILE}"
rsync -azhe ssh --delete${link} --log-file="${LOG_FILE}" "${SRC_FOLDER}" "${BU}"

# *** Remove old backups
bu_count="$(lsdircount "${BUS_FOLDER}")"
if [ "${bu_count}" -gt "${MAX_BUS}" ]; then
  rmfirstdirs "${BUS_FOLDER}" "$((${bu_count} - ${MAX_BUS}))"
fi
