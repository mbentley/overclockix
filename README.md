# Overclockix 
For more information about the Overclockix project, including downloads, see http://www.overclockix.com

## Prerequisites for live-build
In order to work with Overclockix using live-build, you must first meet the following prerequesites:
- I would strongly suggest using a Debian 7.0 (wheezy) amd64 build system.  You may use an i386 system but you will not be able to build amd64 images.
- Install **git** and **live-build** packages installed:  `apt-get install git live-build`

## Building using Docker
In order to help facilitate the building of Overclockix, I have added a Dockerfile 

To pull this image:
`docker pull mbentley/overclockix`

Example usage:
```
docker run --privileged -i -t -e aptproxy=http://192.168.56.2:3142 \
   -e branch=master -v /opt/live:/opt/live mbentley/overclockix build all
```

You can specify how you would like to launch the build environment:

`bash` or no argument - Starts a bash session inside the container

`build all` - Builds all flavors & image types

`build i386` - Builds all i386 images

`build amd64` - Builds all amd64 images

`build i386_iso-hybrid` - Builds i386; iso-hybrid

`build i386_usb-hdd` - Builds i386; usb-hdd

`build amd64_iso-hybrid` - Builds amd64; iso-hybrid

`build amd64_usb-hdd` - Builds amd64; usb-hdd

`release <version>` - Copies the resulting image files as a release to the appropriate directory

`createtorrents <version>` - Create torrents via `transmission-create` for the specified version

There are also environment variables you may specify:

`aptproxy` - configures live-build to use an apt-proxy (defaults - none)

`branch` - specifies which branch of [Overclockix](https://github.com/mbentley/overclockix) you would like to build (default - master)

*Note:* You must run the container with the `--privileged` argument for debootstrap to work.

## Cloning the repository
If you would like to stay consistent with my build environment, I use the **/opt/live/overclockix** directory.  You can use the following command to create the necessary directory structure and then cd to the destination where you will clone the repository:
```
mkdir /opt/live
cd /opt/live
```

From the directory in which you want to clone the repository, execute the following command:
```
git clone https://github.com/mbentley/overclockix.git
```

## Re-create hard links for 'common'
In order to make the management of common files easier, I used hard links on my build system.  These hard link do not transfer properly to github and symlinks do not work with the live-build system.  I have created a script name **create_hard_links** (found in scripts) that will automatically re-create all of the hard links.
If you would like to verify that the hard links have been created, you can execute the following command from the **overclockix** directory where the repo has been cloned:
```
find ./common -type f -printf "%n\t%p\n"
```
This command will output the number of hard links to each file.  Before executing the script, they should all show "1" for the hard link count.  After executing the script, the files under **./common/i386** and **./common/amd64** should show "3" and the files under **./common/all** should show "5".

There may be occasions in which a file will only show "1" after the hard links have been created.  In that case, that would indicate that the file should not be hard linked as it is not in use under any of the builds.

## Build Instructions
Make sure that you are in the repository directory (e.g. **overclockix/i386_iso-hybrid**) and then execute the following commands:
```
lb clean
lb config
lb build
```
There is also a **build.sh** script which will execute the above commands for you in the directory of each release.

## live-build Documentation
For further information on how to use live-build, see the live-build manual:  http://live.debian.net/manual/stable/index.en.html
