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

# Destination folder for backup
readonly BU="${BUS_FOLDER}/${BUID}"

# Log file
readonly LOG_FILE="${BU}.log"

# *** Ensure folder existence if local
if [[ ! "${BUS_FOLDER}" = *:* ]]; then
  mkdir -p "${BUS_FOLDER}"
fi

# *** Create new backup
link=""
bu_count="$(lsdircount "${BUS_FOLDER}")"
if [[ "${bu_count}" -gt 0 ]]; then  # hardlinked to last backup
  link=" --link-dest=$(echo "$(lsdir "${BUS_FOLDER}")" | tail -n 1)"
fi
rm -f "${LOG_FILE}"
rsync -azhe ssh --delete${link} --log-file="${LOG_FILE}" "${SRC_FOLDER}" "${BU}"

# *** Remove old backups
bu_count="$(lsdircount "${BUS_FOLDER}")"
if [ "${bu_count}" -gt "${MAX_BUS}" ]; then
  n="$((${bu_count} - ${MAX_BUS}))"
  bus="$(echo "$(lsdir "${BUS_FOLDER}")" | head -n "${n}")"
  echo "${bus}" | xargs -I {} sh -c 'rm -r "{}" && rm "{}.log"'
fi
