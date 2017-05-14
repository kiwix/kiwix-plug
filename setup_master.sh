#!/bin/bash

KIWIX_X86_STATIC_URL=http://download.kiwix.org/bin/kiwix-linux-i686.tar.bz2
KIWIX_ARM_STATIC_URL=http://download.kiwix.org/bin/kiwix-server-arm.tar.bz2
KIWIX_WINDOWS_URL=http://download.kiwix.org/bin/kiwix-win.zip
KIWIX_OSX_URL=http://download.kiwix.org/bin/kiwix.dmg
KIWIX_ANDROID_URL=http://download.kiwix.org/bin/kiwix.apk
KIWIX_SRC_URL=http://download.kiwix.org/src/kiwix-src.tar.xz
BIN_TO_INSTALL="no"

# Compute script path
BINARY_ORG="$0"
if [ ! ${BINARY_ORG:0:1} = "/" ]
then
   BINARY_ORG=`pwd`/$BINARY_ORG
fi

# Binary target script path (in case of symlink)
BINARY=$BINARY_ORG
while [ `readlink $BINARY` ]
do
    BINARY=`readlink $BINARY`
done

# Compute script dir ($ROOT)
if [ ${BINARY:0:1} = "/" ]
then
    ROOT=`dirname $BINARY`
else
    ROOT=`dirname $BINARY_ORG`/`dirname $BINARY`
    ROOT=`cd $ROOT ; pwd`
fi

# Check if the DNS works
`host -a www.kiwix.org 8.8.8.8 > /dev/null`
EXIT_VALUE=$?
if [ ! "$EXIT_VALUE" = "0" ]
then
    echo "Was not able to resolve www.kiwix.org. Are you access to Internet is OK?"
    exit 1
fi

# Check if the access to Internet works
`ping -c3 www.kiwix.org > /dev/null`
EXIT_VALUE=$?
if [ ! "$EXIT_VALUE" = "0" ]
then
    echo "Was not able to ping www.kiwix.org. Are you access to Internet is OK?"
    BIN_TO_INSTALL="yes"
fi

# Check if the e2fsprogs are installed
E2LABEL=`whereis e2label | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$E2LABEL" = "" ]
then
    echo "You need to install the e2fsprogs (apt-get install e2fsprogs)."
    BIN_TO_INSTALL="yes"
fi

# Check if "mkdosfs" is installed
MKDOSFS=`whereis -b mkdosfs | cut -d" " -f2`
if [ "$MKDOSFS" = "" ]
then
    echo "You need to install the dosfstools (apt-get install dosfstools)."
    BIN_TO_INSTALL="yes"
fi

# Check if "wget" is installed
WGET=`whereis -b wget | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$WGET" = "" ]
then
    echo "You need to install wget (apt-get install wget)."
    BIN_TO_INSTALL="yes"
fi

# Check if "split" is installed
SPLIT=`whereis -b split | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$SPLIT" = "" ]
then
    echo "You need to install split (apt-get install coreutils)."
    exit 1
fi

# Check if "arp-scan" is installed
ARP_SCAN=`whereis -b arp-scan | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$ARP_SCAN" = "" ]
then
    echo "You need to install arp-scan (apt-get install arp-scan)."
    BIN_TO_INSTALL="yes"
fi

# Check if "plink" is installed
PLINK=`whereis -b plink | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$PLINK" = "" ]
then
    echo "You need to install plink (apt-get install putty-tools)."
    BIN_TO_INSTALL="yes"
fi

# Check if "pscp" is installed
PSCP=`whereis -b pscp | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$PSCP" = "" ]
then
    echo "You need to install pscp (apt-get install putty-tools)."
    BIN_TO_INSTALL="yes"
fi

# Check if "beep" is installed
BEEP=`whereis -b beep | cut --delimiter=":" -f2 | cut --delimiter=" " -f2`
if [ "$BEEP" = "" ]
then
    echo "You need to install beep (apt-get install beep)."
    BIN_TO_INSTALL="yes"
fi

# Check if packages need to be installed
if [ "$BIN_TO_INSTALL" = "yes" ]
then
    echo "You need to install thus packages before going further..."
    exit 1
fi

# Make a git update
echo "Resync kiwix-plug code with the online git repository"
if git stash ; then
    git pull origin master
    git stash pop
fi

# Check if should clean
if [ "$1" == "clean" ]
then
    echo "Remove file before a new downoad"
    rm -rf $ROOT/bin/kiwix* $ROOT/bin/.kiwix-*
    rm -rf $ROOT/data/library/library.xml
    rm -rf $ROOT/data/index/*.idx
fi

# Download GNU/Linux static (for kiwix-index)
# NO - just get pre-indexed files
# if [ ! -f "$ROOT/bin/.kiwix.tar.bz2.finished" -o  ! -f "$ROOT/bin/kiwix.tar.bz2" ]
# then
#     rm -f "$ROOT/bin/.kiwix.tar.bz2.finished" "$ROOT/bin/kiwix.tar.bz2"
#     wget -c $KIWIX_X86_STATIC_URL -O "$ROOT/bin/kiwix.tar.bz2"
#     cd "$ROOT/bin/" ; tar -xvf "$ROOT/bin/kiwix.tar.bz2" ; cd ../
#     touch "$ROOT/bin/.kiwix.tar.bz2.finished"
# fi

# Download ARM static (for the kiwix-serve to install)
if [ ! -f "$ROOT/bin/.kiwix-arm.tar.bz2.finished" -o ! -f "$ROOT/bin/kiwix-arm.tar.bz2" ]
then
    rm -f "$ROOT/bin/.kiwix-arm.tar.bz2.finished" "$ROOT/bin/kiwix-arm.tar.bz2"
    wget -c $KIWIX_ARM_STATIC_URL -O "$ROOT/bin/kiwix-arm.tar.bz2"
    cd $ROOT/bin/ ; tar -xvf "$ROOT/bin/kiwix-arm.tar.bz2" ; cd ../
    touch "$ROOT/bin/.kiwix-arm.tar.bz2.finished"
fi

# Download Kiwix for Windows
if [ ! -f "$ROOT/bin/.kiwix.zip.finished" -o ! -f "$ROOT/bin/kiwix.zip" ]
then
    rm -f "$ROOT/bin/.kiwix.zip.finished" "$ROOT/bin/kiwix.zip"
    wget -c $KIWIX_WINDOWS_URL -O "$ROOT/bin/kiwix.zip"
    touch "$ROOT/bin/.kiwix.zip.finished"
fi

# Download Kiwix for OSX
if [ ! -f "$ROOT/bin/.kiwix.dmg.finished" -o ! -f "$ROOT/bin/kiwix.dmg" ]
then
    rm -f "$ROOT/bin/.kiwix.dmg.finished" "$ROOT/bin/kiwix.dmg"
    wget -c $KIWIX_OSX_URL -O "$ROOT/bin/kiwix.dmg"
    touch "$ROOT/bin/.kiwix.dmg.finished"
fi

# Download Kiwix for Android
if [ ! -f "$ROOT/bin/.kiwix.apk.finished" -o ! -f "$ROOT/bin/kiwix.apk" ]
then
    rm -f "$ROOT/bin/.kiwix.apk.finished" "$ROOT/bin/kiwix.apk"
    wget -c $KIWIX_ANDROID_URL -O "$ROOT/bin/kiwix.apk"
    touch "$ROOT/bin/.kiwix.apk.finished"
fi

# Download the sources
if [ ! -f "$ROOT/bin/.kiwix-src.tar.xz.finished" -o ! -f "$ROOT/bin/kiwix-src.tar.xz" ]
then
    rm -f "$ROOT/bin/.kiwix-src.tar.xz.finished" "$ROOT/bin/kiwix-src.tar.xz"
    wget -c $KIWIX_SRC_URL -O "$ROOT/bin/kiwix-src.tar.xz"
    touch "$ROOT/bin/.kiwix-src.tar.xz.finished"
fi

# Rename the ZIM files by adding a "_" at the beginning
# John - hmmm - why? I don't get it - don't do it for now.
# for FILE in `find "$ROOT/data/content/" -name "*.zim*" ; find "$ROOT/data/content/" -name "*.zimaa"`
# do
#     DIRNAME=`dirname "$FILE"`
#     BASENAME=`basename "$FILE"`
#     if [ ${BASENAME:0:1} != "_" ]
#     then
# 	mv "$FILE" "$DIRNAME/_$BASENAME"
#     fi
# done

# Index all ZIM files
# John - no, I'll download them with index instead.
# for ZIM in `find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
# do
#     ZIM=`echo "$ZIM" | sed -e s/\.zimaa/.zim/`
#     BASENAME=`echo "$ZIM" | sed -e "s/.*\///"`
#     IDX="$ROOT/data/index/$BASENAME.idx"
#     if [ -f "$IDX/.finished" ]
#     then
# 	echo "Index of $ZIM already created"
#     else
# 	echo "Indexing $ZIM at $IDX ..."
# 	sleep 3
# 	rm -rf "$IDX"
# 	"$ROOT/bin/kiwix/bin/kiwix-index" --verbose --backend=xapian "$ZIM" "$IDX"
# 	touch "$IDX/.finished"
#     fi
# done

# Check if there is ZIM files in the /data/content
ZIMS=`find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
if [ "$ZIMS" = "" ]
then
    echo "Please put ZIM files in /data/content"
    exit 1
# else
    # NO - get pre-split files
    # for ZIM in `find -L "$ROOT/data/content/" -name "*.zim" -size +2G`
    # do
	# echo "Splitting $ZIM in parts of 2GB..."
	# split --bytes=2000M "$ZIM" "$ZIM"
	# rm "$ZIM"
    # done
fi

# Create the library file "library.xml"
# John - nah, I'll download my own library file - will need to adjust for it's name elsewhere however most likely
# LIBRARY="$ROOT/data/library/library.xml"
# rm -f "$LIBRARY"
# echo "Recreating library at '$LIBRARY'"
# for ZIM in `find "$ROOT/data/content/" -name "*.zim" ; find "$ROOT/data/content/" -name "*.zimaa"`
# do
#     ZIM=`echo "$ZIM" | sed -e s/\.zimaa/.zim/`
#     BASENAME=`echo "$ZIM" | sed -e "s/.*\///"`
#     IDX="$BASENAME.idx"
#     echo "Adding $ZIM to library.xml"
#     "$ROOT/bin/kiwix/bin/kiwix-manage" "$LIBRARY" add "$ZIM" --zimPathToSave="../content/$BASENAME" --indexBackend=xapian --indexPath="../index/$IDX"
# done

# End music
beep -f 659 -l 460 -n -f 784 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 880 -l 230 -n -f 659 -l 230 -n -f 587 -l 230 -n -f 659 -l 460 -n -f 988 -l 340 -n -f 659 -l 230 -n -f 659 -l 110 -n -f 1047 -l 230 -n -f 988 -l 230 -n -f 784 -l 230 -n -f 659 -l 230 -n -f 988 -l 230 -n -f 1318 -l 230 -n -f 659 -l 110 -n -f 587 -l 230 -n -f 587 -l 110 -n -f 494 -l 230 -n -f 740 -l 230 -n -f 659 -l 460
