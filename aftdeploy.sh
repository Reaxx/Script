#!/bin/bash

################################################################################
# Script Name:    afterdeploy.sh
# Version:        0.5
# Author:         Jonny Svensson
# Date:           March 16, 2024
# Description:    This script monitors system statistics, mounts evidence files while running the
#                 given AFT and saves the data to files.
################################################################################

# Function to set parameters
set_params() {
    # Command used to start the process to be evaluated, leave empty for manual use
    appCommand=""
    # Name of the process to be evaluated (used for grep)
    appPrName="test"
    # Default interval between measures (not respected by measures generating large outputs)
    measureInterval=1
    # Hard drive used
    hardDrive=sda
    # Evidence file
    evdFile="/home/kali/Evidence/SCHARDT.dd"
}

# Function to log messages
log() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >>"$log_file"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Function to check if running as root or with sudo
check_root() {
    # Check if running with sudo
    if [ "$(id -u)" != "0" ]; then
        log "This script should be run with sudo."
        exit 1
    fi
}

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

    # Set log file path
    log_file="$folder/log.txt"

    log "Starting statistics"

    # Create directory
    mkdir -p "$folder"
    # Make folder avalbie to all users
    chmod 777 "$folder"

    # Measure RAM, CPU, and disk usage, filter for the given process, and respect the interval
    #top -b -d 1 | awk '/autopsy/ {print strftime("%Y-%m-%d-%H:%M:%S"), $0}'
    # top -b -d "$measureInterval" | grep "$appPrName" >"$processes_file" &
    top -b -d "$measureInterval" | awk "/${appPrName}/ {print strftime(\"%I:%M:%S %p\"), \$0}" >"$processes_file" &

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

pause_until_Y() {
    read -s -r -n 1 -p "Press Y to continue: " input
    echo
    if ($input != "Y" && $input != "y"); then
        pause_until_Y
    fi
}

# Main function
main() {
    # Exit if not root
    check_root

    # Set the global parameters
    set_params

    log "Script $(basename "$0") started."

    # Validate parameters
    validate_params

    # Start measuring system statistics
    start_statistics

    # Mount evidence file
    losetup /dev/loop99 -P "$evdFile"

    log "Evidence mounted"

    # Start process if appCommand is not empty
    if [ -n "$appCommand" ]; then
        log "Deploying $appCommand"
        $appCommand
    else
        log "appCommand is empty. Manually deploy AFT"
        pause_until_Y

    fi

    # Stop measuring system statistics
    stop_statistics

    log "Script done."

    # Make log file available to all users
    chmod 777 "$log_file"

    #Unmount evidence file
    losetup -d /dev/loop99
}

# Call the main function
main
