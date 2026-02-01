# Hytale_Linux_Server_Updater
A simple script which automates updating a Hytale server in a Linux Environment using Hytales own Linux downloader and systemd

## Things to Know first
1) This script assumes you ALREADY have a Hytale server functional using systemd. This is simply to allow updates more efficiently.
2) This script utlizes a ".env" file in the same location as your HytaleServer.jar to pass at least the --assets variable for Hytale server starting.
3) The assets tag within the .env file should be named "HYTALE_ASSETS"
4) This script updates the server in-place. It will replace the HytaleServer.aot and HytaleServer.jar files to perform the updates. If you have not yet begun using this or another script to have backups of past versions of these files, it is recommended that you manually back up your server before using this script
5) I am painfully aware that the console logging used here is ugly and non-standard. It serves its function, however.


## Example .service file used with this script
```
[UNIT]
Description=Runs a Hytale Server
Documentation=https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=steam
WorkingDirectory=/Full/path/to/server/jar/
TimeoutStartSec=300
EnvironmentFile=/Full/path/to/server/jar/.env
ExecStart=/usr/bin/java -XX:AOTCache=HytaleServer.aot -jar $HYTALE_JAR  --assets $HYTALE_ASSETS --allow-op --backup --backup-dir $HYTALE_BACKUP

[Install]
WantedBy=default.target
```

## Example of .env Environment File used in systemd service configuration
```
# .env 
HYTALE_JAR="/Full/path/to/server/jar/HytaleServer.jar"
HYTALE_ASSETS="/Full/path/to/your/hytale/downloader/2026.01.28-87d03be09/Assets.zip"
HYTALE_BACKUP="/Full/path/to/server/jar/hypetale/backups"
```
_Notes: As mentioned above in the Things to know section, the only line required in the .env file is the HYTALE_ASSETS line in order to be updated by the script. The other entries can simply be included in the ExecStart if desired. We use the .env file to alter parameters however to avoid needing to do a systemctl daemon-reload every time an update happens._
