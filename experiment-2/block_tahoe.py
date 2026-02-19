#!/usr/bin/python3.9

# Finds all keys in FirstOfferDateDictionary containing "_26." and sets
# their dates to Tue Jan 01 00:00:00 GMT 2030.

import plistlib
import datetime
import sys

# PLIST = "/Library/Preferences/com.apple.SoftwareUpdate.plist"
PLIST = "com.apple.SoftwareUpdate.plist"

NEW_DATE = datetime.datetime(2030, 1, 1, 0, 0, 0, tzinfo=datetime.timezone.utc)

try:
    with open(PLIST, "rb") as f:
        data = plistlib.load(f)
except FileNotFoundError:
    print(f"Error: Plist not found at {PLIST}")
    sys.exit(1)
except Exception as e:
    print(f"Error reading plist: {e}")
    sys.exit(1)

fodd = data.get("FirstOfferDateDictionary")
if not fodd:
    print("No FirstOfferDateDictionary found.")
    sys.exit(1)

updated = 0

for key in fodd:
    if "_26." not in key:
        continue

    current_date = fodd[key]

    if not isinstance(current_date, datetime.datetime):
        print(f"Warning: Value for {key} is not a date, skipping.")
        continue

    fodd[key] = NEW_DATE

    print(f"Updated {key}: {current_date} -> {NEW_DATE}")
    updated += 1

if updated == 0:
    print("No _26. keys found in FirstOfferDateDictionary.")
    sys.exit(0)

try:
    with open(PLIST, "wb") as f:
        plistlib.dump(data, f, fmt=plistlib.FMT_XML)
    print(f"\nUpdated {updated} key(s) and saved plist.")
except Exception as e:
    print(f"Error writing plist: {e}")
    sys.exit(1)
