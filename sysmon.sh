#!/bin/bash

################################################################################
# Script Name:    sysmon.sh
# Version:        0.5
# Author:         Jonny Svensson
# Date:           March 16, 2024
# Description:    This script monitors system statistics while running the
#                 given process and saves the data to files.
################################################################################

# Function to set parameters
set_params() {
  # Command used to start the process to be evaluated
  appCommand="/snap/bin/autopsy --nosplash"
  # Name of the process to be evaluated (used for grep)
  appPrName="autopsy"
  # Default interval between measures (not respected by measures generating large outputs)
  measureInterval=1
  # Hard drive used
  hardDrive=sda
}

# Log file path
log_file="/home/kali/Script/log.txt"

# Function to log messages
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$log_file"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to check if running as root or with sudo
check_root() {
  if [ "$(id -u)" = "0" ]; then
    log "This script should not be run as root or with sudo."
    exit 1
  fi
}

# Check if running as root or with sudo
if [ "$(id -u)" = "0" ]; then
  echo "This script should not be run as root or with sudo."
  exit 1
fi

# Function to validate parameters
validate_params() {
  # Check if the given hard drive exists
  if ! lsblk | grep -q "$hardDrive"; then
    log "Hard drive $hardDrive does not exist."
    exit 1
  fi
}

# Function to start measuring system statistics
start_statistics() {
  folder="/home/kali/Script/$(generate_filename)$appPrName"
  processes_file="$folder/$(generate_filename "processes").txt"
  cpu_file="$folder/$(generate_filename "cpu").txt"
  mem_file="$folder/$(generate_filename "mem").txt"
  disk_file="$folder/$(generate_filename "disk").txt"

  log "Starting statistics"

  # Create directory
  mkdir -p "$folder"

  # Measure RAM, CPU, and disk usage, filter for the given process, and respect the interval
  top -b -d "$measureInterval" | grep "$appPrName" >"$processes_file" &

  # Measure CPU, memory, and hard disk usage each interval
  sar "$measureInterval" >"$cpu_file" &
  sar "$measureInterval" -r >"$mem_file" &
  sar -d "$measureInterval" | grep "$hardDrive" >"$disk_file" &
}

# Function to generate a filename
generate_filename() {
  local measurement_type=$1
  local date=$(date +%y%m%d%H%M%S)
  local filename="${date}_${measurement_type}"
  echo "$filename"
}

# Function to stop measuring system statistics
stop_statistics() {
  log "Stopping statistics"
  # Stop top command
  pkill "top"
  # Stop sar command
  pkill "sar"
}

# Main function
main() {
  # Check if running as root or with sudo as autopsy wont work with it
  check_root

  # Set the global parameters
  set_params

  log "Script $(basename "$0") started."

  # Validate parameters
  validate_params

  # Start measuring system statistics
  start_statistics

  # Start process
  $appCommand
  # Wait for process to finish, uncomment if needed
  #wait

  # Stop measuring system statistics
  stop_statistics

  log "Script done."
}

# Call the main function
main
