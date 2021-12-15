#!/bin/bash

DESIREDUSER="root"
CURRENTUSER=$(whoami)
if [ "$CURRENTUSER" != "$DESIREDUSER" ]; then
    echo "[!] Please run this script as superuser (i.e., sudo/su)!"
    exit 1
fi

echo "[!] Welcome to Déverser, a simple script to dump onboard SHSH (Blobs) with a valid generator for iOS devices!"
echo "[!] The blobs dumped with this script can be used with futurerestore at a later date (depending on SEP compatibility)."

if ! command -v curl &> /dev/null; then
    echo "[*] ERROR: dependency check failed -- curl could not be found."
    exit 1
elif ! command -v rsync &> /dev/null; then
    echo "[*] ERROR: dependency check failed -- rsync could not be found."
    exit 1
elif ! command -v ssh &> /dev/null; then
    echo "[*] ERROR: dependency check failed -- openssh-client could not be found."
    exit 1
elif ! command -v unzip &> /dev/null; then
    echo "[*] ERROR: dependency check failed -- unzip could not be found."
    exit 1
fi

if ! test -f "/usr/local/bin/img4tool"; then
    echo "[*] ERROR: dependency check failed -- img4tool could not be found."
    echo "[#] Do you want Déverser to download and install img4tool? (y/n)"
    read consent
    if [ $consent == "y" ]; then
        echo "[!] Downloading latest img4tool from Tihmstar's repo..."
        mkdir img4tool && cd img4tool
        curl -L https://github.com/tihmstar/img4tool/releases/latest/download/buildroot_ubuntu-latest.zip --output img4tool-latest.zip
        unzip -q img4tool-latest.zip
        sudo cp buildroot_ubuntu-latest/usr/local/bin/img4tool /usr/local/bin/img4tool
        sudo cp -R buildroot_ubuntu-latest/usr/local/include/img4tool /usr/local/include
        sudo chmod +x /usr/local/bin/img4tool
        cd ..
        rm -rf img4tool/
        if test -f "/usr/local/bin/img4tool"; then
            echo "[!] Successfully installed img4tool!"
        else
            echo "[*] ERROR: Failed to install img4tool!"
            exit 1
        fi
    elif [ $consent == "n" ]; then
        echo "[!] img4tool is required for this script. Please either run this script again and respond 'y' to the install prompt or install it yourself manually (see README.md)."
        exit 1
    else
        echo "[*] ERROR: Unknown input detected. Going to assume you meant 'n'..."
        echo "[!] img4tool is required for this script. Please either run this script again and respond 'y' to the install prompt or install it yourself manually (see README.md)."
        exit 1
    fi
fi

if test -f "dump.raw"; then
    rm -rf dump.raw
fi

echo "[#] Please enter your device's IP address (which can be found in WiFi settings):"
read ip
echo "[!] Device's IP address is ${ip}"
echo "[!] Assuming provided IP is correct. If connecting to the device fails, please ensure that you entered the IP correctly and have openssh installed."
echo "[#] Please enter your device's root password (default is 'alpine'):"
ssh root@${ip} -p 22 "cat /dev/rdisk1 | dd of=dump.raw bs=256 count=$((0x4000))" &> /dev/null
echo "[!] Dumped onboard SHSH to device and preparing to move to this machine..."
echo "[#] Please enter the device's root password again (default is 'alpine'):"
rsync -az --remove-source-files -e 'ssh -p 22' root@${ip}:dump.raw dump.raw

if ! test -f "dump.raw"; then
    echo "[#] ERROR: Failed to to move 'dump.raw' from device to this machine!"
    exit 1
else
    echo "[!] Successfully moved dump.raw to this machine and preparing to convert to SHSH..."
fi

img4tool --convert -s dumped.shsh dump.raw &> /dev/null
if img4tool -s dumped.shsh | grep -q 'failed'; then
    echo "[*] ERROR: Failed to create SHSH from 'dump.raw'!"
    exit 1
fi

ecid=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
mv dumped.shsh ${ecid}.dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename corresponding to its respective device
generator=$(cat ${ecid}.dumped.shsh | grep "<string>0x" | cut -c10-27)

if test -f "${ecid}.dumped.shsh"; then
    echo "[!] Successfully dumped SHSH!"
    echo "[!] The generator for said SHSH is: ${generator}"
    echo "[!] Note: the string of numbers in the filename is your device's ECID."
else
    echo "[*] ERROR: Failed to dump SHSH!"
    exit 1
fi

echo "[@] Originally written by Matty (@moski_dev), made linux compatible by IlanM, and refined by Lightmann."
exit 0
