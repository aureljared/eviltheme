# Eviltheme by Jared Dantis (@aureljared)
# Licensed under GPL v3
# https://github.com/aureljared/eviltheme

cleanup() {
    ui_print "Cleaning up and unmounting filesystems"
    rm -rf $vrRoot $vrBackupStaging
    [ "$SYSTEMLESS" -eq "1" ] && umount $sumnt
    [ "$ART" -eq "0" ] && umount /cache
    umount /system
    umount /data
    umount /preload
}

# These were too long to look clean in update-binary
list_new_sysfiles() {
    echo "$(unzip -l $1 'system/*' | tr -s ' ' ' ' | sed 1,3d | head -n -2 | grep -v "^ 0" | cut -f5 -d' ')"
}
list_new_datafiles() {
    echo "$(unzip -l $1 'data/*' | tr -s ' ' ' ' | sed 1,3d | head -n -2 | grep -v "^ 0" | cut -f5 -d' ')"
}

friendlyname() {
    # Example: Return "Settings" for "Settings.apk"
    tempvar="$(echo $1 | sed 's/.apk//g')"
    echo "$tempvar"
}

# Delete
checkdex_dalvik() {
    if [ -e ./classes.dex ]; then
        echo "system@$1@$2" >> $vrBackupStaging/bytecode.list
        rm -f "/data/dalvik-cache/system@$1@$2@classes.dex"
        rm -f "/cache/dalvik-cache/system@$1@$2@classes.dex"
    fi
}
checkdex_art() {
    appname=$(friendlyname "$2")
    if [ -e ./classes.dex ] || [ -e ./classes.art ]; then
        echo "system@$1@$appname@$2" >> $vrBackupStaging/bytecode.list
        rm -f "/data/dalvik-cache/arm/system@$1@$appname@$2@classes.dex"
        rm -f "/data/dalvik-cache/arm64/system@$1@$appname@$2@classes.dex"
        rm -f "/data/dalvik-cache/arm/system@$1@$appname@$2@classes.art"
        rm -f "/data/dalvik-cache/arm64/system@$1@$appname@$2@classes.art"
    fi
}
checkdex() {
    # checkdex <subfolder in /system> <apk filename>
    [ "$ART" -eq "1" ] && checkdex_art "$@" || checkdex_dalvik "$@"
}

convert_to_octal() {
    perm=0
    [ ! -z "$(echo $1 | grep 'r')" ] && perm=$((perm + 4))
    [ ! -z "$(echo $1 | grep 'w')" ] && perm=$((perm + 2))
    [ ! -z "$(echo $1 | grep 'x')" ] && perm=$((perm + 1))
    echo $perm
}
get_octal_perms() {
    # stat -c is not supported in all recovery versions of busybox
    # so we have to do this manually
    permsString="$(ls -l $1 | tr -s ' ' ' ' | cut -f1 -d' ' | sed -r 's/^.{1}//')"   # rwxr-xr-x
    userPermString="$(echo $permsString | cut -c1-3)"                                # rwx
    groupPermString="$(echo $permsString | cut -c4-6)"                               # r-x
    worldPermString="$(echo $permsString | cut -c7-9)"                               # r-x
    userPerm="$(convert_to_octal $userPermString)"                                   # 7
    groupPerm="$(convert_to_octal $groupPermString)"                                 # 5
    worldPerm="$(convert_to_octal $worldPermString)"                                 # 5
    echo "$userPerm$groupPerm$worldPerm"
}

theme() {
    path="$1/$2" # system/app
    cd "$vrRoot/$path"

    # Create working directories:                  /preload/...      or /magisk/<theme-id>/system/app or (/system)/system/app
    [ "$(echo $1 | cut -f1 -d/)" == "preload" ] && vrTarget="/$path" || vrTarget="$target/$2"
    mkdir -p "$vrTarget"
    mkdir -p "$vrBackupStaging/$path"
    mkdir -p "$vrRoot/apply/$path"

    for f in *.apk; do
        # Set app paths
        [ "$ART" -eq "1" ] && appPath="$path/$(friendlyname $f)/$f" || appPath="$path/$f"     #  system/app/(Browser/)Browser.apk
        [ "$foldername" == "system" ] && origPath="$ROOT/$appPath" || origPath="/$appPath"    # (/system)/system/app/(Browser/)Browser.apk

        # Check if app exists in device
        if [ -f "$origPath" ]; then
            ui_print " => $origPath"
            vrApp="$vrRoot/apply/$appPath.zip"                                                # /data/tmp/eviltheme/apply/system/app/(Browser/)Browser.apk.zip

            # Create app subfolders (ex. Browser/Browser.apk)
            if [ "$ART" -eq "1" ]; then
                mkdir -p "$vrRoot/apply/$path/$(friendlyname $f)"
                [ "$SYSTEMLESS" -eq "1" ] && mkdir -p "$vrTarget/$(friendlyname $f)" || mkdir -p "$vrBackupStaging/$path/$(friendlyname $f)"
            fi

            # Get original UID, GID, permissions, and SELinux context
            appUid="$(ls -l $origPath | awk 'NR==1 {print $3}')"
            appGid="$(ls -l $origPath | awk 'NR==1 {print $4}')"
            appPerms="$(get_octal_perms $origPath)"
            [ "$lsContextSupported" -eq "1" ] && appContext="$(ls -Z $origPath | tr -s ' ' ' ' | cut -f2 -d' ')" || appContext='u:object_r:system_file:s0'
            [ "$themeDebug" -eq "1" ] && echo "$vrOut $appUid $appGid $appPerms '$appContext'" >> $vrBackupStaging/contexts.list

            # Copy APK and backup if not systemless
            cp -c "$origPath" "$vrApp"
            [ "$SYSTEMLESS" -eq "0" ] && cp "$origPath" "$vrBackupStaging/$origPath"

            # Delete files in APK, if any
            cd "$f"
            if [ -e "./delete.list" ]; then
                while IFS='' read item; do
                    $vrEngine/zip -d "$vrApp" "$item"
                done < ./delete.list
                rm -f ./delete.list
            fi

            # Theme APK
            $vrEngine/zip -r "$vrApp" ./*
            mv "$vrApp" "$vrRoot/apply/$appPath"

            # Refresh bytecode if necessary
            [ "$2" == "samsung-framework-res" ] && checkdex "framework@$2" "$f" || checkdex "$2" "$f"

            # Finish up
            [ "$ART" -eq "1" ] && vrOut="$vrTarget/$(friendlyname $f)/$f" || vrOut="$vrTarget/$f"
            cp -f "$vrRoot/apply/$appPath" "$vrOut"
            set_perm $appUid $appGid $appPerms "$vrOut" "$appContext"
            cd "$vrRoot/$path"
        else
            ui_print " !! $origPath does not exist, skipping"
        fi
    done
}

