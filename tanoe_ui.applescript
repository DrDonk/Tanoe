-- tanoe_ui.applescript
-- All-in-one AppleScript UI for tanoe.
-- Manages gdmf.apple.com in /etc/hosts to block macOS update checks.
--
-- Build into a double-clickable app with:
--   osacompile -o Tanoe.app tanoe_ui.applescript

-- Entry point
on run
	showMainMenu()
end run

-- Main menu loop
on showMainMenu()
	set currentStatus to getStatus()

	if currentStatus is "on" then
		set statusLine to "Status: ENABLED (gdmf.apple.com is blocked)"
	else
		set statusLine to "Status: DISABLED (gdmf.apple.com is not blocked)"
	end if

	set dialogResult to display dialog Â
		"Tanoe - macOS Update Blocker" & return & return & Â
		statusLine & return & return & Â
		"What would you like to do?" Â
		buttons {"Quit", "Turn Off", "Turn On"} Â
		default button "Turn On" Â
		with title "Tanoe" Â
		with icon note

	set choice to button returned of dialogResult

	if choice is "Quit" then
		return
	else if choice is "Turn On" then
		if currentStatus is "on" then
			display dialog "Already enabled - gdmf.apple.com is already in /etc/hosts." Â
				buttons {"OK"} default button "OK" with title "Tanoe - Turn On" with icon note
		else
			doTurnOn()
		end if
		showMainMenu()
	else if choice is "Turn Off" then
		if currentStatus is "off" then
			display dialog "Already disabled - gdmf.apple.com is not in /etc/hosts." Â
				buttons {"OK"} default button "OK" with title "Tanoe - Turn Off" with icon note
		else
			doTurnOff()
		end if
		showMainMenu()
	end if
end showMainMenu

-- Check whether the hosts entry is present.
-- Returns "on" or "off".
on getStatus()
	try
		do shell script "grep -q '^127\\.0\\.0\\.1[[:space:]]*gdmf\\.apple\\.com' /etc/hosts"
		return "on"
	on error
		return "off"
	end try
end getStatus

-- Add the hosts entry (requires admin rights)
on doTurnOn()
	-- Check macOS automatic updates setting first
	try
		set autoUpdate to do shell script "defaults read /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload"
		if autoUpdate is "1" then
			set warnResult to display dialog Â
				"Warning: macOS automatic updates are currently enabled." & return & return & Â
				"Tanoe works best when automatic updates are disabled." & return & Â
				"Would you like to open Software Update settings now?" Â
				buttons {"Cancel", "Open Settings", "Continue Anyway"} Â
				default button "Continue Anyway" Â
				with title "Tanoe - Auto Updates Warning" Â
				with icon caution
			set warnChoice to button returned of warnResult
			if warnChoice is "Cancel" then
				return
			else if warnChoice is "Open Settings" then
				do shell script "open 'x-apple.systempreferences:com.apple.Software-Update-Settings.extension'"
				return
			end if
		end if
	end try

	-- Shell script to add entry and flush DNS, run with sudo
	set addScript to "HOSTS_FILE=/etc/hosts
HOST_ENTRY='127.0.0.1 gdmf.apple.com'
COMMENT='# Managed by tanoe'
BACKUP_FILE=\"/etc/hosts.backup.$(date +%Y%m%d_%H%M%S)\"
cp \"$HOSTS_FILE\" \"$BACKUP_FILE\"
if [ -n \"$(tail -c 1 $HOSTS_FILE)\" ]; then
    printf '\n' >> \"$HOSTS_FILE\"
fi
echo \"$HOST_ENTRY  $COMMENT\" >> \"$HOSTS_FILE\"
dscacheutil -flushcache
killall -HUP mDNSResponder 2>/dev/null
echo \"Backup saved to $BACKUP_FILE\""

	try
		set cmdOutput to do shell script addScript with administrator privileges
		display dialog Â
			"Successfully enabled." & return & return & Â
			"gdmf.apple.com has been added to /etc/hosts." & return & Â
			"DNS cache has been flushed." & return & return & Â
			cmdOutput Â
			buttons {"OK"} default button "OK" Â
			with title "Tanoe - Turn On" with icon note
	on error errMsg number errNum
		if errNum is -128 then
			display dialog "Cancelled - no changes were made." Â
				buttons {"OK"} default button "OK" with title "Tanoe" with icon note
		else
			display dialog "Failed to enable." & return & return & "Error: " & errMsg Â
				buttons {"OK"} default button "OK" with title "Tanoe - Error" with icon caution
		end if
	end try
end doTurnOn

-- Remove the hosts entry (requires admin rights)
on doTurnOff()
	set removeScript to "HOSTS_FILE=/etc/hosts
cp \"$HOSTS_FILE\" \"${HOSTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)\"
sed -i.tmp '/^127\\.0\\.0\\.1[[:space:]]*gdmf\\.apple\\.com/d' \"$HOSTS_FILE\"
sed -i.tmp '/^# Managed by tanoe$/d' \"$HOSTS_FILE\"
rm -f \"${HOSTS_FILE}.tmp\"
dscacheutil -flushcache
killall -HUP mDNSResponder 2>/dev/null"

	try
		do shell script removeScript with administrator privileges
		display dialog Â
			"Successfully disabled." & return & return & Â
			"gdmf.apple.com has been removed from /etc/hosts." & return & Â
			"DNS cache has been flushed." Â
			buttons {"OK"} default button "OK" Â
			with title "Tanoe - Turn Off" with icon note
	on error errMsg number errNum
		if errNum is -128 then
			display dialog "Cancelled - no changes were made." Â
				buttons {"OK"} default button "OK" with title "Tanoe" with icon note
		else
			display dialog "Failed to disable." & return & return & "Error: " & errMsg Â
				buttons {"OK"} default button "OK" with title "Tanoe - Error" with icon caution
		end if
	end try
end doTurnOff
