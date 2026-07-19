#!/usr/bin/env bash
set -Eeuo pipefail

USER_NAME="jerry"
USER_ID="$(id -u "$USER_NAME")"

apt-get update
apt-get install -y \
  sudo curl ca-certificates gnupg git jq avahi-daemon \
  pipewire pipewire-pulse wireplumber alsa-utils pulseaudio-utils \
  dbus-user-session

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

cat >/etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

apt-get update
apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

usermod -aG docker,audio "$USER_NAME"

mkdir -p /opt/echofree
cp /opt/echofree-installer/docker-compose.yml /opt/echofree/docker-compose.yml
cp /opt/echofree-installer/echofree.env.example /opt/echofree/.env
install -m 0755 /opt/echofree-installer/echofree-setup /usr/local/sbin/echofree-setup
install -m 0755 /opt/echofree-installer/echofree-status /usr/local/bin/echofree-status

cat >/etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

systemctl enable docker avahi-daemon
loginctl enable-linger "$USER_NAME" || true

# Start the user's PipeWire services at boot without a desktop login.
mkdir -p "/home/${USER_NAME}/.config/systemd/user/default.target.wants"
chown -R "${USER_NAME}:${USER_NAME}" "/home/${USER_NAME}/.config"

cat >/etc/motd <<'EOF'
EchoFree v0.1 prototype

First steps:
  1. Change the default password: passwd
  2. Connect the USB microphone and speaker
  3. Run: sudo echofree-setup
  4. In Home Assistant, accept the discovered ESPHome device

Status:
  echofree-status
EOF
