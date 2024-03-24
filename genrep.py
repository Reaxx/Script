import csv
import os


def prepare_header(filepath):
    # Define the header strings for processes and disk
    header_processes = "PID\t USER\tPR\tNI\t VIRT\tRES\tSHR\tS\t%CPU\t%MEM\tTIME\n"
    header_disk = "DEV\t tps\trkB/s\twkB/s\tdkB/s\tareq-sz\t aqu-sz\tawait\t %util\n"

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


# Read data from the file
with open('data.txt', 'r') as file:
    lines = file.readlines()


folder = "240317184418_test"
# Read all files in folder
for filename in os.listdir(folder):
    headers = {}
    file_path = folder + "/" + filename
    prepare_header(file_path)

    with open(file_path, 'r') as file:

        lines = file.readlines()
        # Open the output CSV file
        with open(filename+'.csv', 'w', newline='') as csvfile:
            writer = csv.writer(csvfile)

            for index, line in enumerate(lines):
                if not line.startswith('Linux') and line.strip():
                    line_a = line.split()

                    # If headers has not been set, assume line is headers
                    if not headers:
                        if "cpu" in filename or "mem" in filename or "disk" in filename:
                            # Remove the first two elements from line_a
                            del line_a[:2]
                            # Add element "timestamp" before the rest of the elements
                            line_a.insert(0, "timestamp")

                        headers = line_a
                        # Write headers to the CSV file
                        writer.writerow(headers)
                    else:
                        if "cpu" in filename or "mem" in filename or "disk" in filename:
                            # Merge element 0 1 together
                            line_a[0] = line_a[0] + ' ' + line_a[1]
                            # Remove element 1 (PM)
                            del line_a[1:2]

                        # Write the line to the CSV file
                        writer.writerow(line_a)
