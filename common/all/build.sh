#!/bin/bash

SCRIPT_HOME="$( cd "$( dirname "$0" )" && pwd )"
cd $SCRIPT_HOME

lb clean --cache -all

if [ -z $1 ]
then
	lb config
else
	lb config --apt-http-proxy "${1}"
fi

time lb build

cd - > /dev/null
