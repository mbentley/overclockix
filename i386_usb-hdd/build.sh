#!/bin/bash

SCRIPT_HOME="$( cd "$( dirname "$0" )" && pwd )"
cd ${SCRIPT_HOME}

lb clean

if [ -z ${1} ]
then
	echo "no proxy specified"
	lb config
else
	echo "using '${1}' for the apt proxy"
	lb config --apt-http-proxy "${1}"
fi

time lb build
RETVAL=$?
cd - > /dev/null

exit ${RETVAL}
