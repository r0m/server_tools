#!/usr/bin/env bash

CFOLDER=$1

if [ ! -f "$CFOLDER" ]; then
    echo "File $CFOLDER doesn't exist..."
    echo "End of $0..."
    exit 1;
fi
# ToDo check if file is a zip archive
CHECK_ZIP_FILE=`file -i "$CFOLDER" | grep -Pi "application/[g]?zip"`
if [ ! -n "$CHECK_ZIP_FILE" ]; then
    echo "File $CFOLDER isn't zip archive..."
    echo "End of $0..."
    exit 1;
fi

CNAME=`basename $CFOLDER`
ALBUMNAME=`echo $CNAME | sed -e 's/[.zip,.tar.gz]//g'`
# folder where located your gallery photo
TARGETDIR="/var/www/photos"
TGALBUMS=$TARGETDIR"/albums/"$ALBUMNAME
TGDOWNLOAD=$TARGETDIR"/downloads"
TMPDIR="/tmp/photosextract_"`date +%Y%m%d`
# web server user (by default : www-data)
WEBADMIN="www-data"

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
case $CNAME in
    *.zip)    unzip $TGDOWNLOAD/$CNAME -d $TMPDIR
	      ;;
    *.tar.gz) tar -C $TMPDIR -xzvf $TGDOWNLOAD/$CNAME
	      ;;
    *)        echo "Unknown format..."
	      exit 0
	      ;;
esac

echo "Create album folder $TGALBUMS..."
mkdir $TGALBUMS/

# format photos for web server
echo "Resize, Orient, and move to album folder all pictures..."
cd $TMPDIR
for UN in `find . -iname "*.JPG" -o -iname "*.PNG" -o -iname "*.jpeg"`; do
    echo -e "\tProcess => "$UN
    mogrify -resize 50x50% $UN $UN
    convert -auto-orient $UN $UN
    mv $UN $TGALBUMS/
done

echo "Store md5sum of $CNAME in ${ALBUMNAME}.md5..."
cd $TGDOWNLOAD
md5sum $CNAME > ${ALBUMNAME}.md5
cd -

if [ $EUID -eq 0 ]; then
    echo "Change owner..."
    chown -R $WEBADMIN: $TGALBUMS
    chown -R $WEBADMIN: $TGDOWNLOAD
else
    echo "No root owner of photos unchanged..."
fi

echo "Clean temp directory..."
rm -rf $TMPDIR
