# Place the script
sudo cp block_tahoe.sh /Library/Scripts/block_tahoe.py
sudo chmod +x /Library/Scripts/block_tahoe.py

# Place the LaunchDaemon
sudo cp net.daveparsons.blocktahoe.plist /Library/LaunchDaemons/net.daveparsons.blocktahoe.plist
sudo chown root:wheel /Library/LaunchDaemons/net.daveparsons.blocktahoe.plist
sudo chmod 644 /Library/LaunchDaemons/net.daveparsons.blocktahoe.plist

# Load it
sudo launchctl load /Library/LaunchDaemons/net.daveparsons.blocktahoe.plist

# Test it
sudo touch /Library/Preferences/com.apple.SoftwareUpdate.plist
tail -f /var/log/block_tahoe.log

# Unload it
sudo launchctl unload /Library/LaunchDaemons/net.daveparsons.blocktahoe.plist

