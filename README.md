# EchoFree v0.1

A first-pass x86_64 appliance installer project for turning a Debian mini PC into a
Home Assistant Linux Voice Assistant satellite.

## Current state

This is a **buildable prototype**, not yet a production release. It creates a
custom Debian 13 netinst ISO with:

- Debian 13 (amd64)
- SSH server
- PipeWire/PulseAudio compatibility
- Docker Engine and Docker Compose
- Linux Voice Assistant container files
- `echofree-setup` first-boot configuration command
- Automatic container restart
- SSD-safe Docker log rotation
- Avahi/mDNS discovery support

## Safety

The automated installer can erase a target disk. Test in a VM first, then on the
Beelink Mini S12 Pro with no important drives attached.


## Build without using a Linux terminal

The included GitHub Actions workflow can build the ISO on GitHub:

1. Create an empty GitHub repository.
2. Upload the contents of this folder.
3. Open **Actions > Build EchoFree ISO > Run workflow**.
4. Open the completed run and download the **EchoFree-amd64-ISO** artifact.

The artifact contains the ISO and its SHA-256 checksum.

## Build host

Use Debian 13 or Ubuntu with:

```bash
sudo apt update
sudo apt install -y xorriso isolinux syslinux-utils curl gzip cpio rsync
```

Then:

```bash
chmod +x build-iso.sh
sudo ./build-iso.sh
```

The output is written to:

```text
output/echofree-amd64.iso
```

## First boot

Log in locally or through SSH and run:

```bash
sudo echofree-setup
```

The wizard asks for:

- room/device name
- network interface
- optional explicit microphone device
- optional explicit speaker device
- wake word
- microphone gain and noise suppression

Home Assistant should then discover the satellite through ESPHome on TCP 6053.

## Default prototype credentials

- User: `jerry`
- Password: `echofree`

Change the password immediately:

```bash
passwd
```

Before a public release, this must be replaced with a secure installer-time
credential workflow.

## Design decision

v0.1 deliberately does **not** require a Home Assistant token. Linux Voice
Assistant exposes an ESPHome-compatible API and is discovered by Home Assistant.
The Home Assistant voice pipeline is selected inside Home Assistant.

## Testing order

1. Build and boot the ISO in a disposable VM.
2. Confirm Debian installation and SSH.
3. Confirm `echofree-setup` runs.
4. Test the ISO on the Beelink with Ethernet.
5. Connect the intended USB microphone/speaker.
6. Confirm discovery in Home Assistant.
7. Tune audio.
8. Only then test cloning/deployment to Dell Micros.
