# Overclockix 
For more information about the Overclockix project, see http://www.overclockix.com

## Prerequisites for live-build
In order to work with Overclockix using live-build, you must first meet the following prerequesites:
- I would strongly suggest using a Debian 7.0 (wheezy) amd64 build system.  You may use an i386 system but you will not be able to build amd64 images.
- Install **git** and **live-build** packages installed:  `apt-get install git live-build`

## Cloning the repository
From the directory in which you want to clone the repository, execute the following command:
```
git clone https://github.com/mbentley/overclockix.git
```

## Build Instructions
Make sure that you are in the repository directory (e.g. overclockix/i386_iso-hybrid) and then execute the following commands:
```
lb clean
lb config
lb build
```
There is also a build.sh script which will execute the above commands for you in the directory of each release.

## live-build Documentation
For further information on how to use live-build, see the live-build manual:  http://live.debian.net/manual/stable/index.en.html
