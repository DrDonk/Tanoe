#!/usr/bin/env zsh
# SPDX-FileCopyrightText: © 2026 David Parsons
# SPDX-License-Identifier: MIT

# Enable debug mode if DEBUG environment variable is set to any non-empty value
[[ -n "$TRACE" ]] && set -x

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Pretty print routines
print_title() { echo "${BOLD}$1${NC}" }
print_status() { echo "${GREEN}✓${NC} $1" }
print_warning() { echo "${YELLOW}⚠${NC} $1" }
print_error() { echo "${RED}✗${NC} $1" }
print_info() { echo "${BLUE}ℹ${NC} $1" }
print_debug() { 
    if [[ -n "$DEBUG" ]]; then
        echo "${MAGENTA}⚙${NC} $1"
    fi
}

# Function to display help
show_help() {
    cat << EOF
Usage: tanoe.sh [OPTION]

Options:
    on          Enable blocker
    off         Disable blocker
    status      Show current status
    help        Display this help message

Examples:
    tanoe.sh on
    tanoe.sh status

EOF
}

# Cleanup function to unmount EFI partition
cleanup() {
    if [[ -n "$MOUNT_POINT" ]] && [[ -n "$EFI_PARTITION" ]]; then
        echo -e "\n${YELLOW}Do you want to unmount the EFI partition? (y/n):${NC} \c"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            print_info "Unmounting EFI partition..."
            if diskutil unmount "$EFI_PARTITION" &>/dev/null; then
                print_status "EFI partition unmounted successfully"
            else
                print_warning "Failed to unmount EFI partition"
            fi
        else
            print_info "EFI partition left mounted at: $MOUNT_POINT"
        fi
    fi
}

trap cleanup EXIT

# Function to find and mount boot EFI partition
mount_efi() {
    
    # Sets global variables:
    # BOOT_VOLUME     - volume used to boot the system
    # CONTAINER_REF   - APFS container with the boot BOOT_VOLUME
    # PHYSICAL_STORE  - physical disk with the boot CONTAINER_REF
    # EFI_PARTITION   - EFI partition on the PHYSICAL_STORE
    # MOUNT_POINT     - mount point for EFI_PARTITION
    # 
    # Returns:
    # 0 - success
    # 1 - failure

    print_status "Finding physical EFI partition with OCLP detection..."

    BOOT_VOLUME=$(df / | tail -1 | awk '{print $1}' | sed 's/\/dev\///')
    print_debug "Boot volume: $BOOT_VOLUME"

    CONTAINER_REF=$(diskutil info -plist "$BOOT_VOLUME" | plutil -extract APFSContainerReference raw - 2>/dev/null)
    if [[ -z "$CONTAINER_REF" ]]; then
        print_error "Not an APFS volume or container not found"
        return 1
    fi

    print_debug "APFS Container: $CONTAINER_REF"

    PHYSICAL_STORE=$(diskutil info -plist "$CONTAINER_REF" | plutil -extract APFSPhysicalStores.0.APFSPhysicalStore raw - 2>/dev/null)
    if [[ -z "$PHYSICAL_STORE" ]]; then
        print_error "Could not find physical store"
        return 1
    fi

    print_debug "Physical disk: $PHYSICAL_STORE"

    EFI_PARTITION="${PHYSICAL_STORE%s*}s1"

    if diskutil list "$PHYSICAL_STORE" | grep -q "$EFI_PARTITION"; then
        print_debug "EFI partition: $EFI_PARTITION"

        MOUNT_POINT=$(diskutil info -plist "$EFI_PARTITION" | plutil -extract MountPoint raw - 2>/dev/null)

        if [[ -n "$MOUNT_POINT" ]]; then
            print_status "Already mounted at: $MOUNT_POINT"
        else
            print_info "Mounting EFI partition..."
            if sudo diskutil mount "$EFI_PARTITION" &>/dev/null; then
                MOUNT_POINT=$(diskutil info -plist "$EFI_PARTITION" | plutil -extract MountPoint raw -)
                print_status "Mounted at: $MOUNT_POINT"
            else
                print_error "Failed to mount EFI partition"
                return 1
            fi
        fi
    else
        print_error "EFI partition $EFI_PARTITION not found"
        return 1
    fi
    return 0
}

# Function to perform detailed OCLP check
check_oclp_detailed() {
    
    # Returns:
    # 0 - success
    # 1 - failure

    local OC_FOLDER="$MOUNT_POINT/EFI/OC"
    local CONFIG_PLIST="$OC_FOLDER/config.plist"
    local oclp_status=0

    print_info "Performing detailed OCLP scan..."

    # Get the OCLP version
    oclp_version=$(plutil -extract "NVRAM.Add.4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102.OCLP-Version" raw "$CONFIG_PLIST" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        print_info "OCLP Version: $oclp_version"
    fi

    # Check EFI/OC structure
    if [[ -d "$MOUNT_POINT/EFI/OC" ]]; then
        print_info "Found OpenCore structure in EFI"

        # Check for OCLP-specific files
        local oclp_indicators=(
            "$OC_FOLDER/OpenCore.efi"
            "$OC_FOLDER/Config.plist"
            "$OC_FOLDER/Kexts"
            "$OC_FOLDER/ACPI"
            "$OC_FOLDER/Tools"
        )

        for indicator in "${oclp_indicators[@]}"; do
            if [[ -e "$indicator" ]]; then
                print_debug "Found: $indicator"
                oclp_status="1"
            fi
        done

        # Check for specific OCLP kexts
        local oclp_kexts=(
            "Lilu.kext"
            "RestrictEvents.kext"
        )

        for kext in "${oclp_kexts[@]}"; do
            if find "$OC_FOLDER/Kexts" -name "$kext" 2>/dev/null | grep -q .; then
                print_debug "Found common OCLP kext: $kext"
                oclp_status=2
            fi
        done
    fi

    # Check for OCLP application
    local oclp_app_paths=(
        "/Applications/OpenCore-Patcher.app"
        "/Library/Application Support/Dortania/OpenCore-Patcher.app"
    )

    for app_path in "${oclp_app_paths[@]}"; do
        if [[ -d "$app_path" ]]; then
            local version=$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "unknown")
            print_debug "OCLP Application found: $app_path (Version $version)"
            oclp_status=3
        fi
    done

    # Final determination
    if [[ $oclp_status -eq 3 ]]; then
        print_status "OpenCore Legacy Patcher is installed on this system"
        return 0
    else
        print_warning "OpenCore Legacy Patcher not detected"
        return 1
    fi
}  

# Function check the revpatch settings
revpatch_check() {
    
    # Sets global variables:
    # ACTUAL_MODEL     - actual Mac model
    # SPOOFED_MODEL    - spoofed Mac model
    # OC_FOLDER     - OpenCore folder 
    # CONFIG_PLIST  - OpenCore config.plist
    # 
    # Returns:
    # 0 - success
    # 1 - failure

    OC_FOLDER="$MOUNT_POINT/EFI/OC"
    CONFIG_PLIST="$OC_FOLDER/config.plist"

    # Check if config.plist exists
    if [[ ! -f "$CONFIG_PLIST" ]]; then
        print_error "Config.plist not found at $CONFIG_PLIST"
        return 1
    fi

    # Analyze config.plist for OCLP signatures
    print_info "Analyzing OpenCore config.plist..."

    # Get actual hardware model
    ACTUAL_MODEL=$(plutil -extract "#Revision.Original-Model" raw "$CONFIG_PLIST" 2>/dev/null)
    if [[ -n "$ACTUAL_MODEL" ]]; then
        print_info "Actual hardware: $ACTUAL_MODEL"
    fi

    # Get spoofed model from NVRAM
    SPOOFED_MODEL=$(plutil -extract "#Revision.Spoofed-Model" raw "$CONFIG_PLIST" 2>/dev/null)
    SPOOFED_MODEL=${SPOOFED_MODEL%% *}

    if [[ -n "$SPOOFED_MODEL" ]]; then
        print_info "Reported model: $SPOOFED_MODEL"

        if [[ "$SPOOFED_MODEL" != "$ACTUAL_MODEL" ]]; then
            print_warning "SPOOFING DETECTED: Hardware is being reported as $SPOOFED_MODEL"
            print_warning "Re-enable VMM mode before updating to a newer macOS version"
        else
            print_status "No spoofing detected - models match"
        fi
    else
        print_status "No spoofing detected - no spoofed model found"
    fi
    
    print_status "OCLP patterns found in config.plist"
    return 0
}

# Function get the revpatch value
revpatch_get() {

    # Sets global variable:
    # REVPATCH     - revpatch value
    # 
    # Returns:
    # 0 - success
    # 1 - failure
 
    local revpatch_status=0
 
    REVPATCH=$(plutil -extract "NVRAM.Add.4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102.revpatch" raw "$CONFIG_PLIST" 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        # Test if REVPATCH is empty string
        if [[ -z $REVPATCH ]]; then
            REVPATCH="none"
        fi
        revpatch_status=0
    else
        revpatch_status=1
    fi
    return $revpatch_status
}

# Function to toggle sbvmm in a comma-separated string
# Usage: revpatch_set "current_value" "on|off"
revpatch_set() {
    local value=$1
    local action=$2
    
    if [[ $action == "on" ]]; then
        # Remove all instances of sbvmm
        value=${value//sbvmm,/}
        value=${value//,sbvmm/}
        value=${value//sbvmm/}
        
        # Clean up any resulting comma issues
        value=${value//,,/,}
        value=${value#,}
        value=${value%,}
        
        # If empty after removal, return "none"
        if [[ -z $value ]]; then
            value="none"
        fi
        
    elif [[ $action == "off" ]]; then
        # If value is "none", replace with sbvmm
        if [[ $value == "none" ]]; then
            value=""
        fi
        
        # Remove any existing sbvmm first (to avoid duplicates)
        value=${value//sbvmm,/}
        value=${value//,sbvmm/}
        value=${value//sbvmm/}
        
        # Clean up commas
        value=${value//,,/,}
        value=${value#,}
        value=${value%,}
        
        # Prepend sbvmm
        if [[ -n $value ]]; then
            value="sbvmm,${value}"
        else
            value="sbvmm"
        fi
        
    else
        print_error "Error: action must be 'on' or 'off'"
        return 1
    fi
    
    # Do the update
    plutil -replace NVRAM.Add.4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102.revpatch -string "$value" "$CONFIG_PLIST"
    if [[ $? -eq 0 ]]; then
        print_debug "New value: $value"
        print_status "Blocking has been changed to $action"
        
        # Validate the write succeeded
        local verify_value=$(plutil -extract "NVRAM.Add.4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102.revpatch" raw "$CONFIG_PLIST" 2>/dev/null)
        if [[ "$verify_value" != "$value" ]]; then
            print_error "Verification failed: value was not written correctly"
            return 1
        fi
    else
        print_error "Error writing to $CONFIG_PLIST"
        return 1
    fi
    return 0
}

setup() {
    if ! mount_efi; then
        exit 1
    fi

    if ! check_oclp_detailed; then
        exit 1
    fi
    
    if ! revpatch_check; then
        exit 1
    fi
}

# Main script execution
print_title "Tanoe Blocker (c) David Parsons, 2026"

OPTION=$1
case $OPTION in
    on)
        setup
        revpatch_get
        revpatch_set "$REVPATCH" "on"
        exit 0
        ;;
    off)
        setup
        revpatch_get
        revpatch_set "$REVPATCH" "off"
        exit 0
        ;;
    status)
        setup
        if revpatch_get; then
            print_status "RestrictEvents revpatch: $REVPATCH"

            # Test if substring is present
            if [[ $REVPATCH == *sbvmm* ]]; then
                print_status "Blocking mode is disabled"
            else
                print_status "Blocking mode is enabled"
            fi
                
        else
            print_warning "RestrictEvents revpatch not found"
            exit 1
        fi
        exit 0
        ;;
    help|--help|-h)
        show_help
        exit 0
        ;;
    "")
        echo "Error: No option provided" >&2
        show_help
        exit 1
        ;;
    *)
        echo "Error: Unknown option '$OPTION'" >&2
        show_help
        exit 1
        ;;
esac

# Should never get here
exit 42
