################################################################################
# Script Name:    genrep.py
# Version:        0.2
# Author:         Jonny Svensson
# Date:           March 25, 2024
# Description:    Takes the results from sysmon.sh and aftdeploy.sh and turn them
#                 csv files as well as generates a report with max, min and avg
#                 values for each value
################################################################################

import csv
import os
import sys


def prepare_header(filepath):
    # Define the header strings for processes and disk
    header_processes = "Time\tPM\t PID\t USER\tPR\tNI\t VIRT\tRES\tSHR\tS\t%CPU\t%MEM\tTIME\tProcess\n"
    header_disk = "Time\tPM\tDEV\t tps\trkB/s\twkB/s\tdkB/s\tareq-sz\t aqu-sz\tawait\t %util\n"

    with open(filepath, 'r+') as file:
        f_line = file.readline()

        # Add header to processes file if it doesn't already have one
        if "processes" in filepath and "PID" not in f_line:
            print("Adding header to processes file")
            contents = file.read()
            file.seek(0)
            file.write(header_processes + contents)

        # Add header to disk file if it doesn't already have one
        if "disk" in filepath and "Filesystem" not in f_line:
            print("Adding header to disk file")
            contents = file.read()
            file.seek(0)
            file.write(header_disk + contents)


def calculate_report(values):
    report_values = {}
    for value in values:
        # Ignores empty values
        if len(values[value]) == 0:
            continue

        report_values[value] = {}

        report_values[value]["max"] = max(values[value])
        report_values[value]["min"] = min(values[value])
        report_values[value]["avg"] = sum(values[value]) / len(values[value])

    return (report_values)


def create_report(folder, filename, values):
    with open(folder+"/"+filename + '_report.txt', 'w') as file:
        for value in values:
            file.write(value + "\n")
            file.write("Max: " + str(values[value]["max"]) + "\n")
            file.write("Min: " + str(values[value]["min"]) + "\n")
            file.write("Avg: " + str(values[value]["avg"]) + "\n\n")


# Main
# Read folder from cli argument
if len(sys.argv) > 1:
    folder = sys.argv[1]

# Read all files in folder
for filename in os.listdir(folder):
    headers = {}
    values = {}

    result_path = folder + "_results"
    # create folder if not exists
    if not os.path.exists(result_path):
        os.makedirs(result_path)

    file_path = folder + "/" + filename
    prepare_header(file_path)

    with open(file_path, 'r') as file:

        lines = file.readlines()
        # Open the output CSV file
        with open(result_path+'/'+filename+'.csv', 'w', newline='') as csvfile:

            writer = csv.writer(csvfile)

            for index, line in enumerate(lines):
                if not line.startswith('Linux') and line.strip():
                    line_array = line.split()

                    # If headers has not been set, assume line is headers
                    if not headers:
                        # Remove the first two elements from line_a
                        del line_array[:2]
                        # Add element "timestamp" before the rest of the elements
                        line_array.insert(0, "timestamp")
                        headers = line_array

                        # Write headers to the CSV file
                        writer.writerow(headers)
                    else:

                        # Skip if line_array has less then 2 elements
                        if len(line_array) < 2:
                            continue

                        # Merge element 0 1 together
                        line_array[0] = line_array[0] + ' ' + line_array[1]
                        # Remove element 1 (PM)
                        del line_array[1:2]

                        # Step through each value in line_array, if they are float, save
                        for index, value in enumerate(line_array):
                            # Try to convert value to float, if it fails continue to next value
                            try:
                                # If value is not float, continue to next value
                                value = float(value)

                                # set current header
                                c_header = headers[index]

                                # check if values[headers[index]] exists, if not create it
                                if c_header not in values:
                                    values[c_header] = []

                                # Skips leading zero-values until testing starts
                                if (value == 0 and len(values[c_header]) == 0):
                                    continue

                                # Add number to the end of header[index]
                                values[c_header].append(value)

                            except:
                                continue

                        # Write the line to the CSV file
                        writer.writerow(line_array)

        r_values = calculate_report(values)
        create_report(result_path, filename, r_values)
