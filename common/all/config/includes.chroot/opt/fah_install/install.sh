#!/bin/bash

## 2011/2/25
## updated to grab the new 6.34 SMP2 client

## 2010/3/19
## edited by splat @ overclockers.com to grab the new 6.29 client

# this is the prompt for select
PS3="Please pick a number: "

################################################################################
function user_or_system()
{
    echo
    if [[ $UID == 0 ]] ; then
        install_type="system"
        echo "Installing as root to the system."
    else
        install_type="user"
        echo "Installing as $USER to $HOME."
    fi

    echo 
    echo "Is this OK?"
    echo
    select resp in {OK,cancel} ; do
        if [[ $resp == "OK" ]] ; then
            break
        elif [[ $resp == "cancel" ]] ; then
            exit 1
        fi
    done
}

################################################################################
function choose_version()
{
    echo
    echo "Choose a client."
    echo
    select resp in \
	"6.02 (32 bit/UP)" \
        "6.34 (64 bit/SMP)" ; do
        if [[ $resp == "6.02 (32 bit/UP)" ]] ; then
            version="6.02"
            break
        elif [[ $resp == "6.34 (64 bit/SMP)" ]] ; then
            version="6.34"
            echo
            echo "To use the SMP client, you must have a 64-bit system."
            echo "You must install the ia32-libs package to run the client."
            echo "Press Control-C to quit if these requirements are not yet fulfilled."
            echo
            read
            break
        fi
    done
}

################################################################################
function setup_env()
{
    if [[ x"$install_type" == x"user" ]] ; then
        fah_dir=$HOME/opt/foldingathome
    elif [[ x"$install_type" == x"system" ]] ; then
        fah_dir=/opt/foldingathome
    fi

    installer_dir=`readlink -f $0 | xargs dirname`
    cd $installer_dir
    config_dir=$fah_dir/config

    if [[ x"$version" == x"6.02" || x"$version" == x"6.34" ]] ; then
        executable=fah6
    fi
        
    # run a client for every cpu
    # but count HyperThreading cpus as one (they show up as two in /proc/cpuinfo)
    # you get more work done when running two clients on an HT CPU, but 
    # it's more useful to the project to run just one, because it will finish faster

    num_cpus=`count_cpus`
}

################################################################################
function is_installed()
{
    if [[ -x $config_dir/$executable && -d $fah_dir/1 ]] ; then
        true
    else
        false
    fi
}

################################################################################
function download_ask()
{
    echo
    echo "I couldn't find the client executable.  If you have it already, please copy it to $config_dir/."
    echo "Do you want me to download it for you?"
    echo
    select resp in {yes,no} ; do
        if [[ $resp == "yes" ]] ; then
            if [[ x"$version" = x"6.34" || x"$version" = x"6.02" ]] ; then
                download
	    fi
            break
        elif [[ $resp == "no" ]] ; then
            echo "Please download the executable and save it to $config_dir."
            echo "Then re-run this script."
            echo "http://www.stanford.edu/group/pandegroup/release/$executable"
            exit 1
        fi
    done
}

function download()
{
    if [[ $version == "6.02" ]] ; then
	tarball=FAH6.02-Linux.tgz
    else
	tarball=FAH6.34-Linux64.tgz
    fi
    rm -f ./$tarball
    secure_url=https://www.stanford.edu/group/pandegroup/folding/release/$tarball
    regular_url=http://www.stanford.edu/group/pandegroup/folding/release/$tarball
    if ! (wget --timeout=30 --tries=3 $secure_url \
	|| wget --timeout=30 --tries=3 $regular_url) ; then
        echo "Downloading Folding@Home failed."
        exit 1
    else
        tar zxf $tarball
    fi
}

################################################################################
function create_dirs()
{
    echo
    echo "Creating directory structure..."
    echo
    test -d $fah_dir || mkdir -p $fah_dir 
    test -d $config_dir || mkdir -p $config_dir
    if [[ ! -d $config_dir ]] ; then
        echo "Could not create directory $config_dir/."
        exit 1
    fi
}

################################################################################
function count_cpus
{
    # run a client for every cpu
    # but count HyperThreading cpus as one (they show up as two in /proc/cpuinfo)
    # you get more work done when running two clients on an HT CPU, but 
    # it's more useful to the project to run just one, because it will finish faster

    # physical id should be unique for each physical cpu, 
    # whether it's a discrete chip or multi core or whatever
    # unfortunately, various kernel/hardware combinations don't report it
    if grep '^physical id' /proc/cpuinfo >/dev/null ; then
        num_cpus=`grep '^physical id' /proc/cpuinfo | awk '{print $NF}' | uniq | wc -l`
    else
        num_cpus=`grep -c '^processor[[:space:]]*:' /proc/cpuinfo `
        num_ht_cpus=`grep 'flags' /proc/cpuinfo | grep -c ' ht '`
        num_cpus=$(( $num_cpus - $num_ht_cpus/2 ))       
    fi

    # in case our math is wrong, there has to be at least one
    if [[ $num_cpus -lt 1 ]] ; then
        num_cpus=1
    fi

    if [[ x"$version" = x"6.34" ]] ; then
        echo 1
    elif [[ x"$version" = x"6.02" ]] ; then
        echo $num_cpus
    fi
}

################################################################################
function install_files()
{
    create_dirs

    if [[ x"$version" = x"6.02" ]] ; then
        cp -f ./mpiexec $config_dir || exit 1
        chmod 555 $config_dir/mpiexec
    fi

    cp -f ./$executable $config_dir || exit 1
    chmod 555 $config_dir/$executable
    
    for cpu_num in `seq 1 $num_cpus`; do 
        client_dir=$fah_dir/$cpu_num
        test -d $client_dir || mkdir -p $client_dir
        cpu_num=$((++cpu_num))
    done
}

################################################################################
function create_fah_user()
{
    groupadd foldingathome
    useradd -d $fah_dir -g foldingathome -s /bin/false foldingathome
}

################################################################################
function setup_start_script
{
    # modify startup script
    sed -i -re "s%^fah_dir=.*$%fah_dir=$fah_dir%" ./foldingathome
    sed -i -re "s%^executable=.*$%executable=$executable%" ./foldingathome

    # install the startup script
    if [[ $install_type == "system" ]] ; then
        # install script to /etc/init.d
        echo
        echo "Adding startup script to /etc/init.d"
        chmod 744 ./foldingathome
        if ! /bin/cp -vf ./foldingathome /etc/init.d/ ; then
            echo "Could not copy startup script to /etc/init.d"
            exit 1
        fi
        
        # start at 99 (last) and kill at 01 (first) when booting/shutting down
        if ! update-rc.d foldingathome defaults 99 01 ; then
            exit 1
        fi

#         echo
#         echo "Do you want to start folding right now?"
#         echo 
#         select resp in {yes,no} ; do
#             if [ x$resp = xyes ] ; then
#                 invoke-rc.d foldingathome start
#                 break
#             elif [ x$resp = xno ] ; then
#                 break
#             fi
#         done
        
        echo
        echo "You can control the client by running /etc/init.d/foldingathome as root."
        echo
        echo "To start folding right now, run \`sudo /etc/init.d/foldingathome start\`."
        echo
        read
        
    elif [[ $install_type == "user" ]] ; then
        echo
        echo "Copying startup script to $fah_dir"
        echo
        if ! /bin/cp -fv ./foldingathome $fah_dir ; then
            echo "Could not copy startup script to $fah_dir"
            exit 1
        fi

        echo
        echo "Do you want to add a cron job to automatically start the client?"
        echo
        select resp in {yes,no} ; do
            if [[ $resp == "yes" ]] ; then
                echo 
                echo "Adding cron job to start the client automatically."
                echo
                tmpfile=`tempfile`
                crontab -l > $tmpfile
                if ! grep foldingathome $tmpfile >&/dev/null ; then
                    echo "0 * * * * $fah_dir/foldingathome start >&/dev/null" >> $tmpfile
                    crontab $tmpfile
                fi
                rm -f $tmpfile
                break
            elif [[ $resp == "no" ]] ; then
                break
            fi
        done
        echo
        echo "You can control the client by running $fah_dir/foldingathome."
        echo
        echo "To start folding right now, run \`$fah_dir/foldingathome start\`."
        echo
        read
    fi
}

################################################################################
function setup_reconfigure_script()
{
    # modify script
    sed -i -re "s%^executable=.*$%executable=$executable%" ./reconfigure.sh

    # install the script
    cp -vf ./reconfigure.sh $fah_dir
}

################################################################################
function setup_config_files()
{
    if [[ $install_type == "system" ]] ; then
        echo 
        echo "Installing global options."
        echo
        chmod 644 ./system.options ./smp_system.options
	if [[ x"$version" == x"6.34" ]] ; then
	    cp -iv --preserve=mode ./smp_system.options /etc/default/foldingathome
	elif [[ x"$version" == x"6.02" ]] ; then
	    cp -iv --preserve=mode ./system.options /etc/default/foldingathome
	fi
    fi

    chmod 644 ./client.options
    for cpu_num in `seq 1 $num_cpus`; do 
        cp -iv --preserve=mode ./client.options $config_dir/client${cpu_num}.options
        cpu_num=$((++cpu_num))
    done

    # not technically a config file, but a good thing to have around
    chmod 644 ./README
    cp -fv ./README $fah_dir
}

################################################################################    
function install()
{
    action="install"

    user_or_system

    choose_version 
    
    # PWD should now be where ever this script is 
    setup_env 

    # check if installed
    if is_installed ; then
        echo "It appears that you have the client installed already."
        echo "Please shutdown any running clients, then run this script"
        echo "with either the 'uninstall' or 'update' options."
        exit 1
    fi

    # setup a client for each processor
    if [[ x"$version" != x"6.34" ]] ; then
        echo
        echo "Found $num_cpus cpus.  I will create one client for every cpu."
        echo "If this number is incorrect, then give the proper number."
        echo "Folding@Home works best when one client runs on each physical CPU."
        echo 
        select resp in {1,2,3,4,5,6,7,8,OK} ; do
            if [[ $resp == "OK" ]] ; then
                break;
            elif [[ $resp -ge 1 && $resp -le 8 ]] ; then
                num_cpus=$resp
                break;
            fi
        done
    fi

    if [[ ! -x ./$executable ]] ; then
        download_ask
    fi

    echo 
    echo "Press enter to see the license.  Press 'q' to exit the license viewer."
    echo
    read
    chmod +x ./$executable
    ./$executable -license | less

    install_files

    echo 
    echo "Creating foldingathome user."
    echo
    if [[ $install_type == "system" ]] ; then
        create_fah_user
    fi	

    # configure
    setup_reconfigure_script
    $fah_dir/reconfigure.sh

    setup_config_files

    setup_start_script
}

################################################################################
function uninstall()
{
    action="uninstall"

    install_type="user"
    setup_env
    if is_installed ; then
        echo
        echo "Remove user installation in $fah_dir?"
        echo
        select resp in {yes,no} ; do
            if [[ $resp == "yes" ]] ; then
                rm -rfv $fah_dir
                tmpfile=`tempfile`
                crontab -l > $tmpfile
                sed -ire 's/^.*foldingathome.*$//g' $tmpfile
                crontab $tmpfile
                rm -f $tmpfile
                break
            elif [[ $resp == "no" ]] ; then
                echo "Cancelled."
                break
            fi
        done
    fi

    install_type="system"
    setup_env
    if is_installed && [[ $UID == 0 ]] ; then
        echo
        echo "Remove system installation in $fah_dir?"
        echo
        select resp in {yes,no} ; do
            if [[ $resp == "yes" ]] ; then
                rm -rfv $fah_dir
                rm -fv /etc/init.d/foldingathome
                update-rc.d -f foldingathome remove
                userdel -r foldingathome
                groupdel foldingathome
                break
            elif [[ $resp == "no" ]] ; then
                echo "Cancelled."
                break
            fi
        done
    fi
}

################################################################################
function update()
{
    action="update"

    user_or_system

    choose_version

    setup_env

    if ! is_installed ; then
        echo "It appears that the client is not installed yet,"
        echo "or you have a different version."
        echo "Please (re)install the client."
        exit 1
    fi

    setup_config_files

    setup_start_script

    # update anything supplied with this script
    setup_reconfigure_script
}

################################################################################
# main program

case $1 in 
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    update)
        update
        ;;
    debug)
        user_or_system
        setup_env
        echo installer_dir = $installer_dir
        ;;
    *)
        echo "Usage: $0 <install|uninstall|update>"
        echo
        echo "This script will install, uninstall, or update the Folding@Home client."
        echo "It is meant for use on Ubuntu Linux systems, but might work for"
        echo "any LSB compliant distribution with SysV-style init."
        ;;
esac

exit

