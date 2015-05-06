#!/usr/bin/env sh

UNZIP="/usr/bin/unzip"
CFOLDER=$1
CNAME=`basename $CFOLDER`
ALBUMNAME=`echo $CNAME | sed 's/.zip//g'`
# folder where located your gallery photo
TARGETDIR="/var/www/photos"
TGALBUMS=$TARGETDIR"/albums/"$ALBUMNAME
TGDOWNLOAD=$TARGETDIR"/downloads"
TMPDIR="/tmp/photosextract"
# web server user (by default : www-data)
WEBADMIN="www-data"

if [ ! -f "$CFOLDER" ]; then
    echo "File $CFOLDER doesn't exist..."
    echo "End of $0..."
    exit 1;
fi

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
    echo "\tResize => "$UN
    mogrify -resize 50x50% $UN $UN
    echo "\tReorient => "$UN
    convert -auto-orient $UN $UN
done

echo "Create album folder $TGALBUMS..."
mkdir $TGALBUMS/

echo "Move pictures to $TGALBUMS..."
mv -f $TMPDIR/* $TGALBUMS/

echo "Change owner..."
chown -R $WEBADMIN: $TGALBUMS
chown -R $WEBADMIN: $TGDOWNLOAD

echo "Clean temp directory..."
rm -rf $TMPDIR
