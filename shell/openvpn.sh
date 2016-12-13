#!/bin/bash

daemon="openvpn"
prog="openvpn-client"
option=$1
conf_file=$2

start() {
    echo -n $"Starting $prog: " 
        if [ -e /var/lock/subsys/openvpn-client ] && [ $(pgrep -fl "openvpn --config $conf_file" | wc -l) -gt 0 ]; then
        echo "Failed to start openvpn for $conf_file.  Process already running, or unable to start"
        exit 1
    fi
    #runuser -l root -c "$daemon --config $conf_file >/dev/null 2>&1 &"
    #$daemon --config $conf_file >/dev/null 2>&1 &
    $daemon --config $conf_file &
    RETVAL=$?
    echo
    [ $RETVAL -eq 0 ] && touch /var/lock/subsys/openvpn-client;
    return $RETVAL
}

stop() {
    echo -n $"Stopping $prog: "
    pid=$(ps -ef | grep "[o]penvpn --config $conf_file" | awk '{ print $2 }')
    kill $pid > /dev/null 2>&1
    RETVAL=$?
    echo
    [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/openvpn-client;
    return $RETVAL
}   

stop_kodi() {
    echo -n $"Stopping $prog: "
    pid=$(ps -ef | grep "[o]penvpn" | awk '{ print $2 }')
    echo "Killing $pid"
    kill $pid > /dev/null 2>&1
    RETVAL=$?
    echo "Returned $RETVAL"
    [ $RETVAL -eq 0 ] && rm -f /var/lock/subsys/openvpn-client;
    return $RETVAL
}


status() {
    pgrep -fl "openvpn --config $conf_file" >/dev/null 2>&1
    RETVAL=$?
    if [ $RETVAL -eq 0 ]; then
        pid=$(ps -ef | grep "[o]penvpn --config $conf_file" | awk '{ print $2 }')
        echo $"$prog (pid $pid) is running..."
    else
        echo $"$prog is stopped or not found"
    fi
}   

restart() {
    stop
    start
}   

if [[ "$#" -ne 2 ]]; then
   option="*"
fi

case "$option" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    stop_kodi)
        stop_kodi
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    condrestart)
        [ -f /var/lock/subsys/openvpn-client ] && restart || :
        ;;
    *)
        echo $"Usage: $0 {start|stop|stop_kodi|status|restart|condrestart} <config_file>"
        exit 1
esac
