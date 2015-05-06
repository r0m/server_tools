#!/usr/bin/env bash

UNZIP="/usr/bin/unzip"
CFOLDER=$1

if [ ! -f "$CFOLDER" ]; then
    echo "File $CFOLDER doesn't exist..."
    echo "End of $0..."
    exit 1;
fi
# ToDo check if file is a zip archive
CHECK_ZIP_FILE=`file -i "$CFOLDER" | grep -i "application/zip"`
if [ ! -n "$CHECK_ZIP_FILE" ]; then
    echo "File $CFOLDER isn't zip archive..."
    echo "End of $0..."
    exit 1;
fi

CNAME=`basename $CFOLDER`
ALBUMNAME=`echo $CNAME | sed 's/.zip//g'`
# folder where located your gallery photo
TARGETDIR="/var/www/photos"
TGALBUMS=$TARGETDIR"/albums/"$ALBUMNAME
TGDOWNLOAD=$TARGETDIR"/downloads"
TMPDIR="/tmp/photosextract_"`date +%Y%m%d`
# web server user (by default : www-data)
WEBADMIN="webadmin"

for UN in $TARGETDIR "$TARGETDIR/albums" $TGDOWNLOAD; do
    if [ ! -d "$UN" ]; then
	echo "Folder $UN doesn't exist..."
	echo "End of $0..."
	exit 1;
    fi
done

echo "Move archive to $TGDOWNLOAD..."
mv $CFOLDER $TGDOWNLOAD

echo "Create temporary directory..."
mkdir -p $TMPDIR

echo "Extract archive to $TGALBUMS..."
$UNZIP $TGDOWNLOAD/$CNAME -d $TMPDIR

# format photos for web server
echo "Resize and Orient all pictures..."
cd $TMPDIR
for UN in `find . -iname "*.JPG" -o -iname "*.PNG" -o -iname "*.jpeg"`; do
    echo -e "\tResize => "$UN
    mogrify -resize 50x50% $UN $UN
    echo -e "\tReorient => "$UN
    convert -auto-orient $UN $UN
done

echo "Create album folder $TGALBUMS..."
mkdir $TGALBUMS/

echo "Move pictures to $TGALBUMS..."
mv -f $TMPDIR/* $TGALBUMS/

if [ $EUID -eq 0 ]; then
    echo "Change owner..."
    chown -R $WEBADMIN: $TGALBUMS
    chown -R $WEBADMIN: $TGDOWNLOAD
else
    echo "No root owner of photos unchanged..."
fi

echo "Clean temp directory..."
rm -rf $TMPDIR
