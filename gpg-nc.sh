#!/bin/sh
#
# This script wraps a netcat session in gpg symmetric encryption, bounced through a shared ssh server.
#
# It is perhaps useful as an example of getting a netcat session to close at EOF on either side.
#
# This is dumb, don't use this.
# If you fully trusted the ssh server, you wouldn't need gpg
# If you had another way to directly reach your peer on a socket, you wouldn't need ssh
#

SERV=some.shared.server
PORT=4000

remote="$1"
if [ "$remote" = "" ] ; then
    echo "Usage: $0 [-l] <remote-person>";
    echo "  -l to listen.";
    echo "  remote-person should match a gpg key like";
    gpg -k |grep uid
    exit 1;
fi

echo "INFO: you may be asked to unlock your gpg keychain for this." 1>&2
echo "INFO: remote-person has to be long enough to match a gpg key uniquely." 1>&2
echo "INFO: there will be buffering because gpg defaults are block ciphers." 1>&2
echo "INFO: interactive terminals are not supported because reasons." 1>&2


case "$1" in
    -l)
        localhost="";
        listen="-l";
        remote="$2";
        ;;
    *)
        localhost="localhost";
        listen="";
        remote="$1";
        ;;
esac
if [ -t 0 ] ; then
    stdin="/dev/null"
    shutdown=""
else
    stdin=""
    shutdown="-N"
fi

# we don't support interactive stdin because then nc never knows when to quit and everything is bad
# A good discussion on the perils of terminating nc
# http://billauer.co.il/blog/2018/07/netcat-nc-stop-quit-disconnect/

echo "INFO: here we go!" 1>&2
gpg --trust-model always -e -r ${remote} -o- ${stdin} | ssh -q -t ${SERV} -- nc ${shutdown} ${listen} ${localhost} ${PORT} | gpg -d --trust-model always
