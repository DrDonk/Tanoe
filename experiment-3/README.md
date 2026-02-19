# Tanoe - stop macOS updates

## Introduction
This simple script allows macOS system updates, such as Tahoe, to be enabled or disabled on an OCLP enabled unsupported Apple Mac. All other updates such as Safari are still available.

The name is a pun "just say no to Tahoe"!

## How it works
OCLP allows macOS updates on unsupported hardware by using RestrictEvents to present
the Mac as a virtual machine. macOS updates can be disabled by toggling the flag to present
the Mac as a VM. The flag is called sbvmm and when enabled does 2 things:

1. The system appears as a VM when kern.hv_vmnm_prsemt kernel flag is checkled
2. The system board ID becomes VMM-X86_64 and not a genuine system such as Macmini7,1 (Mac mini 2014)

macOS software updater and installers always allow a VM to be updated and so this neat 
trick allows older systems with OCLP be updated.

## How to use it

Download a release from xxxx
Unzip the file
Open a terminal and navigate to the folder where you extracted the code 

Check status

<details>

<summary>Status output</summary>

```
Tanoe Blocker (c) David Parsons, 2026
✓ Finding physical EFI partition with OCLP detection...
✓ Already mounted at: /Volumes/EFI
ℹ Performing detailed OCLP scan...
ℹ OCLP Version: 2.4.1
ℹ Found OpenCore structure in EFI
✓ OpenCore Legacy Patcher is installed on this system
ℹ Analyzing OpenCore config.plist...
ℹ Actual hardware: Macmini7,1
ℹ Reported model: Macmini7,1
✓ No spoofing detected - models match
✓ OCLP patterns found in config.plist
✓ RestrictEvents revpatch: none
✓ Blocking mode is enabled

Do you want to unmount the EFI partition? (y/n): y
ℹ Unmounting EFI partition...
✓ EFI partition unmounted successfully
```

</details>

Set block on

<details>

<summary>Setting on output</summary>


```
Tanoe Blocker (c) David Parsons, 2026
✓ Finding physical EFI partition with OCLP detection...
✓ Already mounted at: /Volumes/EFI
ℹ Performing detailed OCLP scan...
ℹ OCLP Version: 2.4.1
ℹ Found OpenCore structure in EFI
✓ OpenCore Legacy Patcher is installed on this system
ℹ Analyzing OpenCore config.plist...
ℹ Actual hardware: Macmini7,1
ℹ Reported model: Macmini7,1
✓ No spoofing detected - models match
✓ OCLP patterns found in config.plist
✓ Blocking has been changed to on

Do you want to unmount the EFI partition? (y/n): y
ℹ Unmounting EFI partition...
✓ EFI partition unmounted successfully
```

</details>

Set block off

<details>

<summary>Setting off output</summary>

```
Tanoe Blocker (c) David Parsons, 2026
✓ Finding physical EFI partition with OCLP detection...
✓ Already mounted at: /Volumes/EFI
ℹ Performing detailed OCLP scan...
ℹ OCLP Version: 2.4.1
ℹ Found OpenCore structure in EFI
✓ OpenCore Legacy Patcher is installed on this system
ℹ Analyzing OpenCore config.plist...
ℹ Actual hardware: Macmini7,1
ℹ Reported model: Macmini7,1
✓ No spoofing detected - models match
✓ OCLP patterns found in config.plist
✓ Blocking has been changed to off

Do you want to unmount the EFI partition? (y/n): y
ℹ Unmounting EFI partition...
✓ EFI partition unmounted successfully
```

</details>

## Limitations
* All system update including point releases will also be filtered out
* Watch out for spoofed Macs as running macOS updates or installs can trash your system
 
(C) David Parsons, 2026