#!/usr/local/bin/bash
. $MUNIN_LIBDIR/plugins/plugin.sh
. $MUNIN_LIBDIR/plugins/_database.new

# directory to check
ID=${0##*/dir_size_}
DIR=${DIRS[$ID]:-/var/log/}
# unique id, just in case you got multiple such scripts, change id as needed (i guess it shoudl be obsolete, not tested)
NAME=${DIRnames[$ID]:-${DIR}}

if [ "$1" = "autoconf" ]; then
        if [ -d $DIR ]; then
            echo "yes"
            exit 0
        else
            echo "no (check your path)"
            exit 1
        fi
fi

if [ "$1" = "config" ]; then
        echo "graph_title Directory size of ${NAME}"
        echo "graph_vlabel size in bytes"
        echo "graph_category disk"
        echo "graph_info Size of ${DIR}"
        echo "ds.label size"
        echo "ds.info Shows du -sk for specified directory"
        echo "ds.warning ${DIRwarnings[$ID]}"
        echo "ds.critical ${DIRcriticals[$ID]}"
        exit 0
fi

echo -n "ds.value "
if [ -d ${DIR} ]; then
    SIZE=`du -sk ${DIR} | cut -f1`
    echo `expr ${SIZE} \* 1024 `
    exit 0
else
    echo "U"
    exit 1
fi
