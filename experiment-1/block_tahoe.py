#!/usr/bin/python3.9

# Removes any entry in RecommendedUpdates where "Display Name" starts with "macOS Tahoe"

import plistlib
import sys

# PLIST = "/Library/Preferences/com.apple.SoftwareUpdate.plist"
PLIST = "com.apple.SoftwareUpdate.plist"

try:
    with open(PLIST, "rb") as f:
        data = plistlib.load(f)
except FileNotFoundError:
    print(f"Error: Plist not found at {PLIST}")
    sys.exit(1)
except Exception as e:
    print(f"Error reading plist: {e}")
    sys.exit(1)

updates = data.get("RecommendedUpdates")
if not updates:
    print("No RecommendedUpdates found.")
    sys.exit(1)

filtered = []
removed = 0

for entry in updates:
    display_name = entry.get("Display Name", "")
    if display_name.startswith("macOS Tahoe"):
        print(f"Removing entry: {display_name}")
        removed += 1
    else:
        filtered.append(entry)

if removed == 0:
    print("No macOS Tahoe entries found.")
    sys.exit(0)

data["RecommendedUpdates"] = filtered

try:
    with open(PLIST, "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_XML)
    print(f"\nRemoved {removed} entry/entries and saved plist.")
except Exception as e:
    print(f"Error writing plist: {e}")
    sys.exit(1)
    