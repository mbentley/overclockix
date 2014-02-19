#!/bin/bash

lb clean

if [ -z $1 ]
then
	lb config
else
	lb config --apt-http-proxy $1
fi

time lb build
