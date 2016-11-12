#!/bin/bash

#################
# Variable init #
#################
pidfile=/tmp/`basename $0 | cut -d'.' -f1`.pid
config_file="${HOME}/.backup_flow"

########################
# Function declaration #
########################
parse_command()
{
    tmp_parameters=`getopt -o nh --long new-config,help -- "$1"`
    eval set -- "$tmp_parameters"
    while true ; do
	case "$1" in
	    -n|--new-config)
		config_file; sexit 0;;
	    -h|--help)
		display_usage 0;;
	    --) shift; break;;
	    *) display_usage 1;;
	esac
    done
}

display_usage()
{
    echo -e "Usage: `basename $0` [-n|--new-config] [-h|--help]"
    echo -e "\t-n|--new-config: Create or overwrite config with default config"
    echo -e "\t-h|--help: Display this help"
    sexit $1
}

config_file()
{
    if [ -f "$config_file" ]; then
	while [[ "$answer" != "y" ]] && [[ "$answer" != "n" ]]
	do 
	    echo -n "$config_file already exist. Do you want averwrite [y/n]? "
	    read answer
	    answer=$(tr '[:upper:]' '[:lower:]' <<< $answer)
	done 
    fi

    if [ "$answer" == "n" ]; then
	sexit 0
    fi

    echo -n "Create $config_file ["
    cat << EOF > $config_file
# orig of backup tree
backup_tree=${HOME}/backup
# lts directory
lts_dir=backup.lts
# list of srv backup to manage
srvlist=srv1
archivetype=tar.gz
md5sumfile=md5sum.txt
# remove daily backup older than daytokeep
#    before remove, purge tool verify if number of backup is > daytokeep
daytokeep=30
# remove lts backup older than yeartokeep
#    before remove, purge tool verify if new lts backup for current month is create
yeartokeep=1
EOF
    
    if [ -f $config_file ]; then
	echo "ok]"
	sexit 0
    else
	echo "failed]"
	echo "Please create $config_file manually..."
	sexit 1
    fi
}

set_config()
{
    source $config_file
    date_today=`date +%Y%m%d`
}

check_requirement()
{
    echo -n "Check requirement ["
    
    if [ "$archivetype" == "" ]; then
	echo "failed]"
	echo -e "\tarchivetype var isn't set. Please correct $config_file..."
    fi

    if ! [ $daytokeep -eq $daytokeep 2> /dev/null  ] || [ "$daytokeep" == "" ]; then
	echo "failed]"
	echo -e "\tdaytokeep var isn't number. Please correct $config_file..."
	sexit 1
    fi
    
    if ! [ $yeartokeep -eq $yeartokeep 2> /dev/null ] || [ "$yeartokeep" == "" ]; then
	echo "failed]"
	echo -e "\tyeartokeep var isn't number. Please correct $config_file..."
	sexit 1
    fi

    echo "ok]"
}

manage_pid()
{
    if [ "$1" == "check" ]; then
	if [ -f $pidfile ]; then
	    pid=`cat $pidfile`
	    ps -p $pid &>/dev/null
	if [ $? -eq "0" ]; then
	    echo "$0 is running..."
	    exit 1
	fi
	rm -f $pidfile
	fi
    elif [ "$1" == "create" ]; then
	echo $$ > $pidfile
    elif [ "$1" == "rm" ]; then
	rm -f $pidfile
    fi
}

get_daily_backup()
{
    check_exist=`ssh $srv "if [ -e ~/backup/${backup_archive} ] && [ -e ~/backup/${md5sum_archive} ] ; then echo 0; else echo 1; fi" 2>/dev/null`
    if [ "$check_exist" == "0" ];
    then
	rsync -avz -e "ssh -F $HOME/.ssh/config" $srv:~/backup/${backup_archive} ${backup_dir} &> /dev/null
	# Todo: don't use rsync but ssh cat $md5sum_archive >> $md5sumfile
	rsync -avz -e "ssh -F $HOME/.ssh/config" $srv:~/backup/${md5sum_archive} ${backup_dir} &> /dev/null

	# ToDo check if rsync output ok
	ssh $srv "rm -f ~/backup/$backup_archive ~/backup/$md5sum_archive"
	
	if [ -f "${backup_dir}/$md5sum_archive" ]; then
	    cat ${backup_dir}/$md5sum_archive >> ${backup_dir}/${md5sumfile}
	    rm -f ${backup_dir}/$md5sum_archive
	fi
	echo "ok]"
	return 0
    else
	echo "failed]"
	echo -e "\t\tError no available backup on $srv"
	return 1
    fi
}

manage_lts_backup ()
{
    currentlts=`date +%Y%m`
    if [ ! -d "${backup_dir}/${lts_dir}" ]; then
	mkdir ${backup_dir}/${lts_dir} &>/dev/null
	if [ $? -ne 0 ]; then
	    echo "failed]"
	    echo -e "\t\tFailed to create lts directory (${backup_dir}/${lts_dir})..."
	    return 1
	fi
    fi
    
    ls ${backup_dir}/${lts_dir}/${srv}_backup_${currentlts}*.${archivetype} &> /dev/null
    if [ $? -ne 0 ]; then
	archive_to_copy=`ls -rt ${backup_dir}/${srv}_backup_${currentlts}*.$archivetype 2>/dev/null | tail -n 1`
	if [ "$archive_to_copy" != "" ]; then
	    cp -prf $archive_to_copy ${backup_dir}/${lts_dir}/
	    archive_to_copy=`basename $archive_to_copy`
	    grep $archive_to_copy ${backup_dir}/$md5sumfile >> ${backup_dir}/${lts_dir}/$md5sumfile
	    echo "ok]"
	    return 0
	else
	    echo "failed]"
	    echo -e "\t\tNo daily backup exist to create current lts backup"
	    return 1
	fi
    else
	echo "ok]"
	echo -e "\t\tlts backup already exist for `date +%Y-%m`"
	return 1
    fi
}

purge()
{
    tmp_dir=$1
    timetokeep=$2
    nbarchive=`ls ${tmp_dir}/${srv}_backup_*.tar.gz | wc -l`
    if [ $nbarchive -le $timetokeep ]; then
	echo "ok]"
    	echo -e "\t\tthere are only $nbarchive archive. no clean!"
	return 0
    else
	# keep always daytokeep archive
	nbarchive=$((nbarchive - $timetokeep))
	# Todo: sort by date in archive name
	archivelist=`ls ${tmp_dir}/${srv}_backup_*.tar.gz | sort | head -n $nbarchive`
    
	for archive in $archivelist
	do
	    rm -f $archive &>/dev/null
	    archive=`basename $archive`
	    sed -e "/$archive/d" -i ${tmp_dir}/$md5sumfile
	done
	echo "ok]"
	echo -e "\t\t$nbarchive removed..."
	return 0
    fi
}


check_archive()
{
    cd $1 &> /dev/null
    result_md5=`md5sum -c $md5sumfile 2>/dev/null`
    if [ $? -eq 0 ]; then
	echo -n "ok]"
    else
	echo -n "failed]"
    fi
    echo $result_md5 | sed -e "s/$srv/\n\t\t$srv/g"
    cd - &> /dev/null
}

sexit()
{
    manage_pid rm
    echo -e "\n--- End of `basename $0` ---"
    exit $1
}

##########################
# Begin of backup_mgr.sh #
##########################

echo -e "--- Begin of `basename $0` ---\n"

# Check if $0 isn't running
manage_pid check
# if not -> create pidfile
manage_pid create

# Parse command line option
parse_command $@

if [ ! -f $config_file ]; then
    echo "$config_file doesn't exist!"
    echo "Run `basename $0` with option -n|--new-config"
    sexit 1
fi

set_config
check_requirement

for srv in $srvlist
do
    echo "Process for $srv..."
    echo -e "\tConfig for $srv:"
    backup_dir="${backup_tree}/vm_${srv}"
    backup_archive="${srv}_backup_${date_today}.${archivetype}"
    md5sum_archive="${srv}_backup_${date_today}.md5"
    echo -e "\t\tbackup directory: $backup_dir"
    echo -e "\t\ttoday backup: $backup_archive"
    echo -e "\t\ttoday md5sum file: $md5sum_archive"
    echo -e "\t\tDay to keep (daily backup): $daytokeep"
    echo -e "\t\tYear to keep (lts backup): $yeartokeep"

    if [ ! -d "$backup_dir" ]; then
	echo -n -e "\n\tCreate backup dir ["
	mkdir -p $backup_dir &> /dev/null
	if [ $? -eq 0 ]; then
	    echo "ok]"
	else
	    echo "failed]"
	    sexit 1
	fi
	
    fi
    echo -n -e "\n\tGet daily backup ["
    get_daily_backup

    echo -n -e "\n\tManage lts backup ["
    manage_lts_backup

    echo -n -e "\n\tPurge daily archive ["
    purge $backup_dir $daytokeep

    echo -n -e "\n\tPurge lts archive ["
    purge $backup_dir/$lts_dir $((yeartokeep*12))
    
    echo -n -e "\n\tCheck daily archive integrity ["
    check_archive ${backup_dir}
    echo -n -e "\n\tCheck lts archive integrity ["
    check_archive ${backup_dir}/${lts_dir}
done

sexit 0
