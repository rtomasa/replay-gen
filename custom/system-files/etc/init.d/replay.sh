#!/bin/sh
### BEGIN INIT INFO
# Provides:          replay
# Required-Start:    $all
# Required-Stop:
# Default-Start:      5
# Default-Stop:
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
        while true; do
            /opt/replay/replay
            RETVAL=$?
            if [ $RETVAL -ne 0 ]; then
                sleep 2  # Optional: Add a delay before restarting
            else
                break
            fi
        done
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
