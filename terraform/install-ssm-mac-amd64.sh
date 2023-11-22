#!/bin/sh

curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac_arm64/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
rm -rf sessionmanager-bundle sessionmanager-bundle.zip

# NOTE: to uninstall, simply run
# sudo rm -rf /usr/local/sessionmanagerplugin
# sudo rm /usr/local/bin/session-manager-plugin
