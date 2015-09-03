# server tools
Tools for server

photostodl
----------
### Informations
This tools resize and re-orient photos for web usage and push all in photos gallery

### requirements
- imagemagick
- file
- unzip

### Installation
Put the script in root bin folder or server web user bin

### Usage
```
photostodl.sh /path/to/archive/photos.zip
```

get_backup.sh
-------------
### Informations
This tools get backup archive from list of server and remove archive older than 10 days

### requirements
- rsync, ssh
- generate ssh {private,public} key and push public on server to backup
- pattern name of archive : ${SERVER_NAME}_backup_`date +%Y%m%d`.tar.gz

### Installation
Put this script in backup user bin and add exec permission (chmod + get_backup.sh). In addition, create new cron job to get automatically archive.

### Usage
```
get_backup.sh
```

check_archive.sh
----------------
### Informations
This tools check archive integrity

### requirements
- md5sum
- md5sum.txt in all where there are archive. This file contain md5sum of each archive in 1 folder

### Installation
Put this script in backup user bin and add exec permission. In addtion, create new cron job to check automatically integrity archive.

### Usage
```
check_archive.sh
```