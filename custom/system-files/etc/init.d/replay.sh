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
    	if [ -f /media/sd/replay ]; then
            mv -f /media/sd/replay /opt/replay
        fi
        cd /opt/replay || exit 1
	/opt/replay/replay
        ;;
    stop)
        # No-op
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
