#!/bin/bash
###############################################################################
###############################################################################
###############################################################################
###                                                                         ###
###                                                                         ###
###   Hytale Server Linux Updater V 1.0                                     ###
###                                                                         ###
###   Author: Pyromancer3D                                                  ###
###   Released on: 2026-02-01                                               ###
###                                                                         ###
###   This script assumes a few things:                                     ###
###   1) You use systemd / systemctl to run your Hytale Server              ###
###                                                                         ###
###   2) You are using an ".env" file to pass some or all of                ###
###          your arguments for the service to use                          ###
###                                                                         ###
###      2a) The .env file should be in the same directory as your          ###
###              HytaleServer.jar and HytaleServer.aot files.               ###
###                                                                         ###
###      2b) within this .env file, the only property this script           ###
###              cares about is a value named HYTALE_ASSETS                 ###
###              All other properties can be whatever you prefer.           ###
###                                                                         ###
###   3) You do not mind your server being updated in-place                 ###
###          (backup current version if it is your first time running       ###
###          to avoid corruption of in-place updates of Hytaleserver.jar    ###
###          and HytaleServer.aot)                                          ###
###                                                                         ###
###   4) I'm sorry the console output logging is ugly and non-standard      ###
###                                                                         ###
###                                                                         ###
###############################################################################
###############################################################################
###############################################################################



timestamp=""
downloadAttempts=2
serviceName="hytale-server.service"
gamePath="/Full/path/to/your/server/jar"
basePath="/Full/path/to/your/hytale/downloader"
hytaleDownloader="$basePath/hytale-downloader-linux-amd64"
version="$($hytaleDownloader -print-version)"
extractPath="$basePath/$version"
hytaleZip="$basePath/$version.zip"



updateTime () {
        timestamp="$(date +"%Y-%m-%d::%T.%3N -- ")"
}

checkVersionPath () {
        updateTime
        echo $timestamp "Checking for directory " $extractPath

        if [ -d "$extractPath" ]; then
                echo -e "\tVersion Directory exists. Exiting."
                exit 0
        else
                echo -e "\tChecking Status of Hytale Server"

                if systemctl is-active --quiet "$serviceName"; then
                        echo -e "\t$serviceName is running, stopping service."
                        stopService
                else
                        echo -e "\t$serviceName is not running, continuing update."
                fi

                echo -e "\tCreating: " $extractPath
                mkdir $extractPath
        fi
}

getNewHytaleVersion () {
        while [ $downloadAttempts -gt 0 ]
        do
                downloadAttempts=$((downloadAttempts - 1))
                updateTime
                echo $timestamp "Downloading Hytale Version: $version to $hytaleZip"
                echo -e "\tDownload attempts remaining: $downloadAttempts"
                $hytaleDownloader > /dev/null
                updateTime
                echo $timestamp "Validating zip file $hytaleZip"
                if unzip -t $hytaleZip > /dev/null; then
                        echo -e "\tzip file $hytaleZip is valid. Continuing."
                        return 0
                else
                        echo -e "\tMax attempts reached. cleaning up and exiting."
                        rmdir $extractPath
                        echo -e "\t\tEmpty directory $extractPath removed."
                        rm $hytaleZip
                        echo -e "\t\t zip file $hytaleZip removed."
                        exit 1
                fi
        done
}

extractNewHytaleVersion () {
        updateTime
        echo $timestamp "Extracting $hytaleZip to $extractPath"
        unzip $hytaleZip -d $extractPath > /dev/null
        updateTime
        echo $timestamp "Extraction of $hytaleZip successful"
        # Confirm multiple files exist after extraction and do cleanups as we move along
        if [ $(find $extractPath -maxdepth 5 -type f | wc -l) -gt 1 ]; then
                echo -e "\tMultiple files in extract location validated."
                rm $hytaleZip
                echo -e "\tBase zip file $hytaleZip has been removed after extraction."
                return 0
        else
                echo -e "\tFewer than two(2) files or directories exists in $extractPath. Cleaning up and exiting."
                rm -rf $extractPath
                echo -e "\t\tDirectory $extractPath removed."
                rm $hytaleZip
                echo -e "\t\tZip File $hytaleZip removed."
                exit 1
        fi
}

updateServer () {
        updateTime
        echo $timestamp "Copying HytaleServer.aot to $gamePath/"
        if diff -sq $extractPath/Server/HytaleServer.aot $gamePath/HytaleServer.aot; then
                echo -e "\tHytaleServer.aot already updated!"
        else
                cp $extractPath/Server/HytaleServer.aot $gamePath/
                if diff -sq $extractPath/Server/HytaleServer.aot $gamePath/HytaleServer.aot; then
                        echo -e "\tHytaleServer.aot successfully updated!"
                else
                        echo -e "\tHytaleServer.aot update FAILED!"
                fi
        fi

        updateTime
        echo $timestamp "Copying HytaleServer.jar to $gamePath/"
        if diff -sq $extractPath/Server/HytaleServer.jar $gamePath/HytaleServer.jar; then
                echo -e "\tHytaleServer.jar already updated!"
        else
                cp $extractPath/Server/HytaleServer.jar $gamePath/
                if diff -sq $extractPath/Server/HytaleServer.jar $gamePath/HytaleServer.jar; then
                        echo -e "\tHytaleServer.jar successfully updated!"
                else
                        echo -e "\tHytaleServer.jar update FAILED!"
                fi
        fi

        updateEnvironmentFile

        # Update completed
        updateTime
        echo $timestamp "Hytale service can now be started."

        startService

        echo $timestamp "Hytale Server in $gamePath updated to $version"
}

updateEnvironmentFile () {
        updateTime
        echo $timestamp "Updating $gamePath/.env with new Assets.zip location."
        echo "Old $gamePath/.env contents:"
        cat $gamePath/.env | grep Assets.zip
        sed -i "s|.*HYTALE_ASSETS.*|HYTALE_ASSETS=\\\"$extractPath/Assets.zip\\\"|" $gamePath/.env
        echo "New $gamePath/.env contents:"
        cat $gamePath/.env | grep Assets.zip
}

stopService () {
        updateTime
        echo $timestamp "Stopping $serviceName."
        sudo systemctl stop $serviceName
        sleep 5
        if systemctl is-active --quiet "$serviceName"; then
                echo -e "\t$serviceName still running, aborting update."
                exit 1
        else
                echo -e "\t$serviceName is stopped."
        fi
}

startService () {
        updateTime
        echo $timestamp "Starting $serviceName."
        sudo systemctl start $serviceName
        sleep 5
        if systemctl is-active --quiet "$serviceName"; then
                echo -e "\t$serviceName is running!"
        else
                echo -e "\t$serviceName is not running, check systemctl logs for more information!"
                exit 1
        fi
}

cleanupFiles () {
        updateTime
        echo $timestamp "Cleaning up all files from aborted or failed run."
        rm -rf $extractPath
        echo -e "\tDirectory $extractPath removed!"
        if [[ -f "$hytaleZip" ]]; then
                rm $hytaleZip
                echo -e "\tZip file $hytaleZip removed!"
        else
                echo -e "\t$hytaleZip does not exist, continuing."
        fi
}



sudo systemctl is-active --quiet "$serviceName"

# Check if there is a need to update
checkVersionPath

# Download the new version using the downloader
getNewHytaleVersion

# Extract new version to newly created folder
extractNewHytaleVersion

# Update the server files and Environment variables for the service to function properly
updateServer

exit 0
