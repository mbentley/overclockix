#!/bin/sh

# Original version by Jonathan Kotta <jpkottaATgmailDOTcom>

# configuration script for Linux Folding@Home client

# this script is assumed to be in the Folding@Home directory
fah_dir=`dirname $0`

# vvvvv this line is modified by the installer vvvvv
executable=fah6
# ^^^^^ this line is modified by the installer ^^^^^

config_dir=$fah_dir/config

if [ ! -x $config_dir/$executable ] ; then
    echo "Could not find $executable in $config_dir/."
    exit 1
fi

# configure the client
cd $config_dir
./$executable -configonly

cd $fah_dir
# setup a client for each processor
for cpu_num in [1-9] ; do
    client_dir=$fah_dir/$cpu_num
    cp -f $config_dir/$executable $client_dir
    cp -f $config_dir/machinedependent.dat $client_dir
    cp -f $config_dir/MyFolding.html $client_dir
    cp -f $config_dir/client.cfg $client_dir
    cp -r $config_dir/mpiexec $client_dir
    /bin/sed -i -e "s/machineid=.*/machineid=$cpu_num/" $client_dir/client.cfg
done

# if running as root, chown all files to the foldingathome user
if [ x"$UID" = x0 -o x"$UID" = x -o x"$UID" = xroot ] ; then
    chown -R foldingathome:foldingathome $fah_dir
    chmod -R o+r $fah_dir
fi