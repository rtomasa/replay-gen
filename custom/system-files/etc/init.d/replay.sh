#!/bin/sh
### BEGIN INIT INFO
# Provides:          replay
# Required-Start:    $all
# Required-Stop:
# Default-Start:      5
# Default-Stop:       0 1 6
# Short-Description: Starts RePlay frontend
# Description:
### END INIT INFO

case "$1" in
    start)
    	echo 0 > /proc/sys/kernel/printk  # Set to show only emergency messages
    	
        if [ -f /media/sd/replay ]; then
            mv -f /media/sd/replay /opt/replay
        fi
        cd /opt/replay || exit 1

        # Autoreload on crash
        /opt/replay/replay
        ;;
    
    stop)
        # No-op, but you can add a kill command to stop the process if necessary
        ;;
    
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
