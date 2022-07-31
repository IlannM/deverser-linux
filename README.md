# Déverser-linux
**[Original (macOS) script](https://github.com/MatthewPierson/deverser) by [@moski_dev](https://twitter.com/moski_dev)**

## Dependencies
### General
	sudo apt install curl libssl1.1 openssh-client rsync sudo unzip

### img4tool
	mkdir img4tool && cd img4tool

	curl -L https://github.com/tihmstar/img4tool/releases/latest/download/buildroot_ubuntu-latest.zip --output img4tool-latest.zip

	unzip img4tool-latest.zip

	sudo cp buildroot_ubuntu-latest/usr/local/bin/img4tool /usr/local/bin/img4tool

	sudo chmod +x /usr/local/bin/img4tool

	sudo cp -R buildroot_ubuntu-latest/usr/local/include/img4tool /usr/local/include

	cd .. && rm -r img4tool

### On your idevice:
Install `openssh` from your package manager or via cli with

	sudo apt install openssh

## Before running the script
	chmod +x deverser-linux.sh

Ensure that your idevice is connected to the same WiFi network as your pc and test the ssh connection by running `ssh root@your_device_ip_address` and entering your root password when prompted. Once you've confirmed that you can access your device, type `exit`.

**Note**: the default root password is "alpine" and should be changed if you haven't changed it already by typing `su`, logging in with "alpine," typing `passwd`, and following the prompts.

## Running the script
	sudo ./deverser-linux.sh

If you've done everything correctly, you should see a .shsh2 file in your current working directory!

## Credits
- Matty (@moski_dev) for the original script
- Tihmstar (@tihmstar) for creating img4tool
- IlanM for adding linux support
- Lightmann for various refinements
