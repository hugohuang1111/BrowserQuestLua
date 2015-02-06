#!/bin/bash

selfFolder=$(cd `dirname $0`; pwd)
clientFolder='../client/BrowserQuestLua/src/app/network/'
serverFolder='../server/network/'

for fileName in `ls ${selfFolder}`;
do
    file="${clientFolder}${fileName}"
    if [ -f $file ]; then
    	rm $file
    fi
    file="${serverFolder}${fileName}"
    if [ -f $file ]; then
    	rm $file
    fi
done

