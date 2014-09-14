#!/sbin/sh

# Enhanced VRTheme engine v1.5
# Copyright Aurel Jared Dantis, 2014.
#
# Original VRTheme engine is copyright
# VillainROM 2011. All rights reserved.
# Edify-like methods defined below are
# copyright Chainfire 2011.

# Declare busybox and output file descriptor
bb="/tmp/busybox"
OUTFD=$(ps | grep -v "grep" | grep -o -E "update_binary(.*)" | cut -d " " -f 3);

[ $OUTFD != "" ] || OUTFD=$(ps | grep -v "grep" | grep -o -E "updater(.*)" | cut -d " " -f 3);

# Declare location shortcuts
f1=/sdcard/vrtheme/system/app
f2=/sdcard/vrtheme/preload/system/app
f3=/sdcard/vrtheme/system/framework
f4=/sdcard/vrtheme/data/sec_app

# Define some methods
ui_print() {
  if [ $OUTFD != "" ]; then
    echo "ui_print ${1} " 1>&$OUTFD;
    echo "ui_print " 1>&$OUTFD;
  else
    echo "${1}";
  fi;
}

dir() {
	$bb mkdir -p $1
}

zpln() {
	/tmp/zipalign -f -v 4 $1 ./aligned/$1
}

zip() {
	/tmp/zip -r $1 $2
}

checkdex() {
	if [ -f ./classes.dex ]; then
		echo "# This is a flag for cleanup.sh" > /sdcard/vrtheme/flags/$1
		echo "# to delete this app's dex entry" >> /sdcard/vrtheme/flags/$1
	fi
}

# cleanup.sh will look here to see what apps need their dex entries refreshed.
dir /sdcard/vrtheme/flags

# Remove placeholder files that will otherwise inhibit proper themeing.
$bb rm -f /sdcard/vrtheme/data/sec_data/placeholder
$bb rm -f /sdcard/vrtheme/system/app/placeholder
$bb rm -f /sdcard/vrtheme/system/framework/placeholder
$bb rm -f /sdcard/vrtheme/preload/symlink/system/app/placeholder
$bb rm -f /data/sec_data/placeholder
$bb rm -f /data/app/placeholder
$bb rm -f /system/app/placeholder
$bb rm -f /system/framework/placeholder

# Back up original APKs
ui_print "- Backing up apps"
[ -f /sdcard/vrtheme/preload/symlink/system/app/* ] && sysapps=1 || sysapps=0
if [ $sysapps == "1" ]; then
	dir /sdcard/vrtheme/backup/system/app
	dir /sdcard/vrtheme/apply/system/app
	for f in $(ls $f1)
	do
	  ui_print " - $f"
	  cp /system/app/$f /sdcard/vrtheme/apply/system/app/
	  cp /system/app/$f /sdcard/vrtheme/backup/system/app/
	done
	ui_print ""
fi

[ -f /sdcard/vrtheme/preload/symlink/system/app/* ] && preload=1 || preload=0
if [ $preload == "1" ]; then
	ui_print "- Backing up preload apps"
	dir /sdcard/vrtheme-backup/preload/symlink/system/app
	dir /sdcard/vrtheme/apply/preload/symlink/system/app
	for f in $(ls $f2)
	do
		ui_print " - $f"
		cp /preload/symlink/system/app/$f /sdcard/vrtheme/apply/preload/symlink/system/app/
		cp /preload/symlink/system/app/$f /sdcard/vrtheme-backup/preload/symlink/system/app/
	done
	ui_print "Backups done for preload apps"
	ui_print ""
fi

[ -f /sdcard/vrtheme/system/framework/* ] && framework=1 || framework=0
if [ $framework == "1" ]; then
	dir /sdcard/vrtheme-backup/system/framework
	dir /sdcard/vrtheme/apply/system/framework
	for f in $(ls $f3)
	do
		ui_print " - $f"
		cp /system/framework/$f /sdcard/vrtheme/apply/system/framework/
		cp /system/framework/$f /sdcard/vrtheme-backup/system/framework/
	done
fi

[ -f /sdcard/vrtheme/data/sec_data/* ] && datasecapps=1 || datasecapps=0
if [ $datasecapps == "1" ]; then
	dir /sdcard/vrtheme-backup/data/sec_data/
	dir /sdcard/vrtheme/apply/data/sec_data/
	for f in $(ls $f4)
	do
		ui_print " - $f"
		cp /data/sec_data/$f /sdcard/vrtheme/apply/data/sec_data/
		cp /data/sec_data/$f /sdcard/vrtheme-backup/data/sec_data/
	done
fi

# Theme the apps
ui_print "- Themeing apps"

if [ $sysapps == "1" ]; then
	cd /sdcard/vrtheme/apply/system/app/
	for f in $(ls $f1)
	do
	  ui_print "* $f"
	  cd /sdcard/vrtheme/system/app/$f/
	  mv /sdcard/vrtheme/apply/system/app/$f /sdcard/vrtheme/apply/system/app/$f.zip
	  zip /sdcard/vrtheme/apply/system/app/$f.zip *
	  mv /sdcard/vrtheme/apply/system/app/$f.zip /sdcard/vrtheme/apply/system/app/$f
	  checkdex $f
	done
fi

if [ $preload == "1" ]; then
	cd /sdcard/vrtheme/apply/preload/symlink/system/app/
	for f in $(ls $f2)
	do
	  ui_print " - $f"
	  cd /sdcard/vrtheme/preload/symlinkl/system/app/$f/
	  mv /sdcard/vrtheme/apply/preload/symlink/system/app/$f /sdcard/vrtheme/apply/preload/symlink/system/app/$f.zip
	  zip /sdcard/vrtheme/apply/preload/symlink/system/app/$f.zip *
	  mv /sdcard/vrtheme/apply/preload/symlink/system/app/$f.zip /sdcard/vrtheme/apply/preload/symlink/system/app/$f
	  checkdex $f
	done
fi

if [ $framework == "1" ]; then
	cd /sdcard/vrtheme/apply/system/framework/
	for f in $(ls $f3)
	do
	  ui_print " - $f"
	  cd /sdcard/vrtheme/system/framework/$f/
	  mv /sdcard/vrtheme/apply/system/framework/$f /sdcard/vrtheme/apply/system/framework/$f.zip
	  zip /sdcard/vrtheme/apply/system/framework/$f.zip *
	  mv /sdcard/vrtheme/apply/system/framework/$f.zip /sdcard/vrtheme/apply/system/framework/$f
	  checkdex $f
	done
fi

if [ $datasecapps == "1" ]; then
	cd /sdcard/vrtheme/apply/data/sec_data/
	for f in $(ls $f4)
	do
	  ui_print " - $f"
	  cd /sdcard/vrtheme/data/sec_data/$f/
	  mv /sdcard/vrtheme/apply/data/sec_data/$f /sdcard/vrtheme/apply/data/sec_data/$f.zip
	  zip /sdcard/vrtheme/apply/data/sec_data/$f.zip *
	  mv /sdcard/vrtheme/apply/data/sec_data/$f.zip /sdcard/vrtheme/apply/data/sec_data/$f
	  checkdex $f
	done
fi

# Zipalign all the APKs
ui_print "- Zipaligning themed apps"
if [ $sysapps == "1" ]; then
	cd /sdcard/vrtheme/apply/system/app/
	$bb mkdir aligned
	for f in $(ls *.apk)
	do
	  zpln $f
	done
fi

if [ $preload == "1" ]; then
	cd /sdcard/vrtheme/apply/preload/symlink/system/app/
	$bb mkdir aligned
	for f in $(ls *.apk)
	do
	  zpln $f
	done
fi

if [ $framework == "1" ]; then
	cd /sdcard/vrtheme/apply/system/framework/
	$bb mkdir aligned
	for f in $(ls *.apk)
	do
	  zpln $f
	done
fi

if [ $datasecapps == "1" ]; then
	cd /sdcard/vrtheme/apply/data/sec_data/
	$bb mkdir aligned
	for f in $(ls *.apk)
	do
	  zpln $f
	done
fi

# Move each new app back to its original location
if [ $sysapps == "1" ]; then
	cd /sdcard/vrtheme/apply/system/app/aligned/
	cp * /system/app/
	chmod 644 /system/app/*
fi

if [ $preload == "1" ]; then
	cd /sdcard/vrtheme/apply/preload/symlink/system/app/aligned/
	cp * /preload/symlink/system/app/
	chmod 644 /preload/symlink/system/app/*
fi

if [ $framework == "1" ]; then
	cd /sdcard/vrtheme/apply/system/framework/aligned/
	cp * /system/framework
	chmod 644 /system/framework/*
fi

if [ $datasecapps == "1" ]; then
	cd /sdcard/vrtheme/apply/data/sec_data/aligned/
	cp * /data/sec_data/
	chmod 644 /data/sec_data/*
fi

exit 0