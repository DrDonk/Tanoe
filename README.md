# Tanoe - stop macOS updates

## Introduction
This simple script allows macOS system updates, such as Tahoe, to be enabled or disabled on 
an OCLP enabled unsupported Apple Mac. All other updates such as Safari are still available.

It is also useful for virtualised macOS where updates are always displayed.

**The name is a pun "just say no to Tahoe"!**

## How it works
macOS calls an Apple hosted service to find macOS system updates relevant to that Mac.
OCLP Macs and VMs present themselves as a virtualised Mac which means the Apple OTA update
service returns any newer macOS major and minor updates independent of the underlying machine
type.

This service is accessed through a URL gdmf.apple.com. To stop these updates we need to block 
access to this URL and the simplest way is to block it through an entry in the hosts file
located in the /etc folder on your Mac. This is done by adding a line like this to the file.

`127.0.0.1   gdmf.apple.com`

This redirects the URL to the host machine, which of course cannot provide the relevant details.
macOS sees this as no updates.

There are 2 things to be aware of if you use this solution.

> [!NOTE]  
> All other updates such as Safari, Command Line Tools for Xcode and security updates etc.
will continue to be updated.

> [!IMPORTANT]  
> No macOS updates will be presented, for example, macOS 26 Tahoe upgrades or Sequoia or Sonoma minor updates. If you need to run a minor update you will need to toggle the blocker off, run the update and then re-enable it.

## How to use it
1. Download a release from [Releases](https://github.com/DrDonk/Tanoe/releases) on GitHub.
2. Unzip the downloaded file.
3. Open a terminal and navigate to the folder where you extracted the files.

> [!NOTE]  
> Updating the /etc/hosts file requires admin privileges and you will be prompted for your password.

### Enable the blocker
Run `./tanoe on`

```
admin@sequoihoe ~ % ./tanoe on 
Adding entry to /etc/hosts...
Backup created: ./hosts.backup.20260205_134308
✓ Successfully added entry
Flushing DNS cache...
Updating available updates...
Software Update Tool

Finding available software
Software Update found the following new or updated software:
* Label: Command Line Tools for Xcode-16.2
	Title: Command Line Tools for Xcode, Version: 16.2, Size: 751786KiB, Recommended: YES, 
* Label: Command Line Tools for Xcode-16.4
	Title: Command Line Tools for Xcode, Version: 16.4, Size: 861558KiB, Recommended: YES, 
* Label: Command Line Tools for Xcode 26.2-26.2
	Title: Command Line Tools for Xcode 26.2, Version: 26.2, Size: 858715KiB, Recommended: YES, 
* Label: Safari26.2SequoiaAuto-26.2
	Title: Safari, Version: 26.2, Size: 224749KiB, Recommended: YES, 
```

### Disable the blocker
Run `./tanoe off`

```
admin@sequoihoe ~ % ./tanoe off
Removing entry from /etc/hosts...
✓ Successfully removed entry
Flushing DNS cache...
Updating available updates...
Software Update Tool

Finding available software
Software Update found the following new or updated software:
* Label: Command Line Tools for Xcode-16.2
	Title: Command Line Tools for Xcode, Version: 16.2, Size: 751786KiB, Recommended: YES, 
* Label: Command Line Tools for Xcode-16.4
	Title: Command Line Tools for Xcode, Version: 16.4, Size: 861558KiB, Recommended: YES, 
* Label: Command Line Tools for Xcode 26.2-26.2
	Title: Command Line Tools for Xcode 26.2, Version: 26.2, Size: 858715KiB, Recommended: YES, 
* Label: Safari26.2SequoiaAuto-26.2
	Title: Safari, Version: 26.2, Size: 224749KiB, Recommended: YES, 
* Label: macOS Sequoia 15.7.3-24G419
	Title: macOS Sequoia 15.7.3, Version: 15.7.3, Size: 947432KiB, Recommended: YES, Action: restart, 
* Label: macOS Tahoe 26.2-25C56
	Title: macOS Tahoe 26.2, Version: 26.2, Size: 5047881KiB, Recommended: YES, Action: restart, 
```

### Check status
Run `./tanoe status`

```
admin@sequoihoe ~ % ./tanoe status
✓ Status: ENABLED
  Entry '127.0.0.1 gdmf.apple.com' is present in /etc/hosts
  
admin@sequoihoe ~ % ./tanoe status
✗ Status: DISABLED
  Entry '127.0.0.1 gdmf.apple.com' is not present in /etc/hosts
```

(C) David Parsons, 2026