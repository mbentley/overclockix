#!/bin/bash

lb clean

if [ -z $1 ]
then
	echo 'lb config'
	lb config
else
	echo 'lb config --apt-http-proxy "${1}"'
	lb config --apt-http-proxy "${1}"
fi

time lb build
