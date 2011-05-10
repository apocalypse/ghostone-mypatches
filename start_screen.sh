# This isn't really a script, but a HOWTO :)
# If you want the ghost server to start automatically on server reboot
# this method will work ( tested on my debian 5.0 server on linode )

# Just make sure that /etc/rc.local exists and is executable

# Also, make sure that /etc/init.d/rc.local is enabled

# Then, just add this line:
#su - ghost -c "cd /home/ghost/ghost++ && /usr/bin/screen -d -m -S ghost /home/ghost/ghost++/ghost++"

# Be sure to add it before the exit 0 line!

# Then you're good to go!
