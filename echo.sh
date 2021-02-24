#!/usr/local/bin/bash

if [ "$1" = "autoconf" ]; then
        echo "yes"
        exit 0
fi

if [ "$1" = "config" ]; then
        echo "graph_title Server working"
        echo "graph_args --upper-limit 1 -l 0"
        echo "graph_vlabel yes/no"
        echo "graph_category system"
        echo "graph_info Test if server works..."
        echo "echo.label Working"
        echo "echo.warning 0.9:"
        echo "echo.critical 0.9:"
        exit 0
fi

echo "echo.value 1"
