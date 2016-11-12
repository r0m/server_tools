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
$ photostodl.sh /path/to/archive/photos.zip
```

backup_server.sh
----------------
### Informations
This tools create an archive of your server

### requirements
- This script must be launch in root
- mysqldump, tar, md5sum

### Installation
Put this script in root bin folder. replace folder1 folder2 file1 file2 by your data folder or file. In addition, create new cron job.

### Usage
```
$ backup_server.sh
```


backup_mgr.sh
-------------
### Informations
This tools get backup archive from list of server, create lts archive, remove old archive, and check integrity with md5sum.

### requirements
- rsync, ssh, md5sum
- generate ssh {private,public} key and push public on server to backup
- pattern name of archive : ${SERVER_NAME}_backup_`date +%Y%m%d`.tar.gz

### Installation
Put this script in backup user bin and add exec permission (chmod + get_backup.sh). First of all, create a new config file and update with your own informations
```
$ backup_mgr.sh --new-config
```
In addition, create new cron job to get automatically archive.

### Usage
```
$ backup_mgr.sh
```
