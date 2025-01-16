#! /usr/bin/env python3

import os, csv, grp, pwd

def get_group_name(gid):
    try:
        return grp.getgrgid(gid).gr_name
    except KeyError:
        return "Unknown"

def get_user_name(uid):
    try:
        return pwd.getpwuid(uid).pw_name
    except KeyError:
        return "Unknown"


# Open the existing CSV file and create a new one for output

if os.path.exists('gids.csv'):
    with open('gids.csv', mode='r', newline='') as infile, open('groups.csv', mode='w', newline='') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile)

        # Write header for the new CSV file
        header = next(reader)  # Skip the header row in the input file
        writer.writerow(['GID', 'groupname'])

        # Read each row from the original file, look up the group name, and write to the new file
        for row in reader:
            if not row:
                print("Skipping empty row")
                continue
            try:
                gid = int(row[0])  # Assuming GID is the first column
                group_name = get_group_name(gid)
                writer.writerow([gid, group_name])
                print(f"Processed GID: {gid}, Group: {group_name}")  # Debugging print
            except ValueError:
                # Handle the case where the conversion to int fails
                print(f"Skipping invalid row: {row}")


if os.path.exists('uids.csv'):
    print('----------------------------------------')
    with open('uids.csv', mode='r', newline='') as infile, open('users.csv', mode='w', newline='') as outfile:
        reader = csv.reader(infile)
        writer = csv.writer(outfile)

        # Write header for the new CSV file
        header = next(reader)  # Skip the header row in the input file
        writer.writerow(['UID', 'username'])

        # Read each row from the original file, look up the group name, and write to the new file
        for row in reader:
            if not row:
                print("Skipping empty row")
                continue
            try:
                uid = int(row[0])  # Assuming GID is the first column
                user_name = get_user_name(uid)
                writer.writerow([uid, user_name])
                print(f"Processed UID: {uid}, User: {user_name}")  # Debugging print
            except ValueError:
                # Handle the case where the conversion to int fails
                print(f"Skipping invalid row: {row}")
