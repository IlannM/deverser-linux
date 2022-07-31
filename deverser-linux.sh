#!/usr/bin/env bash

echo "[!] Welcome to Déverser, a simple script to dump onboard SHSH (Blobs) with a valid generator for iOS devices!"
echo "[!] The blobs dumped with this script can be used with futurerestore at a later date (depending on SEP compatibility)."

if ! [[ -x $(command -v curl) ]]; then
    echo "[*] ERROR: dependency check failed -- curl could not be found."
    exit 1
elif ! [[ -x $(command -v rsync) ]]; then
    echo "[*] ERROR: dependency check failed -- rsync could not be found."
    exit 1
elif ! [[ -x $(command -v ssh) ]]; then
    echo "[*] ERROR: dependency check failed -- openssh-client could not be found."
    exit 1
elif ! [[ -x $(command -v sudo) ]]; then
    echo "[*] ERROR: dependency check failed -- sudo could not be found."
    exit 1
elif ! [[ -x $(command -v unzip) ]]; then
    echo "[*] ERROR: dependency check failed -- unzip could not be found."
    exit 1
fi

if ! [[ -f "/usr/local/bin/img4tool" ]]; then
    while true; do
        echo "[*] ERROR: dependency check failed -- img4tool could not be found."
        read -p "[#] Would you like Déverser to download and install img4tool for you? (y/n)" consent
        if [[ ${consent,,} == "y" || ${consent,,} == "yes" ]]; then
            echo "[!] Downloading latest img4tool from Tihmstar's repo..."
            mkdir img4tool && cd img4tool
            curl -L https://github.com/tihmstar/img4tool/releases/latest/download/buildroot_ubuntu-latest.zip --output img4tool-latest.zip
            unzip -q img4tool-latest.zip
            echo "[#] These next few steps require sudo; please enter your root password if prompted:"
            sudo cp buildroot_ubuntu-latest/usr/local/bin/img4tool /usr/local/bin/img4tool
            sudo chmod +x /usr/local/bin/img4tool
            sudo cp -R buildroot_ubuntu-latest/usr/local/include/img4tool /usr/local/include
            cd .. && rm -rf img4tool/
            if [[ -f "/usr/local/bin/img4tool" ]]; then
                echo "[!] Successfully installed img4tool!"
                break
            else
                echo "[*] ERROR: Failed to install img4tool!"
                exit 1
            fi
        elif [[ ${consent,,} == "n" || ${consent,,} == "no" ]]; then
            echo "[!] img4tool is required for this script. Please either run this script again and respond 'y' to the install prompt or install it yourself manually (see README.md)."
            exit 1
        fi
    done
fi

if [[ -f "dump.raw" ]]; then
    rm -rf dump.raw
fi

read -p "[#] Please enter your device's IP address (which can be found in WiFi settings):" ip
echo "[!] Device's IP address is ${ip}"
echo "[!] Assuming provided IP is correct. If connecting to the device fails, please ensure that you entered the IP correctly and have openssh installed."
echo "[#] Please enter your device's root password (default is 'alpine'):"
ssh root@${ip} -p 22 "cat /dev/rdisk1 | dd of=dump.raw bs=256 count=$((0x4000))" &> /dev/null
echo "[!] Dumped onboard SHSH to device and preparing to move to this machine..."
echo "[#] Please enter the device's root password again (default is 'alpine'):"
rsync -az --remove-source-files -e 'ssh -p 22' root@${ip}:dump.raw dump.raw

if [[ -f "dump.raw" ]]; then
    echo "[!] Successfully moved dump.raw to this machine and preparing to convert to SHSH..."
else
    echo "[#] ERROR: Failed to to move 'dump.raw' from device to this machine!"
    exit 2
fi

img4tool --convert -s dumped.shsh dump.raw &> /dev/null
if img4tool -s dumped.shsh | grep -q 'failed'; then
    echo "[*] ERROR: Failed to create SHSH from 'dump.raw'!"
    exit 3
fi

ECID=$(img4tool -s dumped.shsh | grep "ECID" | cut -c13-)
mv dumped.shsh $ECID.dumped.shsh # Allows multiple devices to be dumped as each dump/converted SHSH will have a filename corresponding to its respective device
GENERATOR=$(cat $ECID.dumped.shsh | grep "<string>0x" | cut -c10-27)

if [[ -f "$ECID.dumped.shsh" ]]; then
    echo "[!] Successfully dumped SHSH!"
    echo "[!] The generator for said SHSH is: $GENERATOR"
    echo "[!] Note: the string of numbers in the filename is your device's ECID."
else
    echo "[*] ERROR: Failed to dump SHSH!"
    exit 4
fi

echo "[@] Originally written by Matty (@moski_dev), made linux compatible by IlanM, and refined by Lightmann."
