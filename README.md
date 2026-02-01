# Hytale_Linux_Server_Updater
A simple script which automates updating a Hytale server in a Linux Environment using Hytales own Linux downloader and systemd

## Things to Know first
1) This script assumes you ALREADY have a Hytale server functional using systemd. This is simply to allow updates more efficiently.
2) This script utlizes a ".env" file in the same location as your HytaleServer.jar to pass at least the --assets variable for Hytale server starting.
3) The assets tag within the .env file should be named "HYTALE_ASSETS"
4) This script updates the server in-place. It will replace the HytaleServer.aot and HytaleServer.jar files to perform the updates. If you have not yet begun using this or another script to have backups of past versions of these files, it is recommended that you manually back up your server before using this script
5) I am painfully aware that the console logging used here is ugly and non-standard. It serves its function, however.
