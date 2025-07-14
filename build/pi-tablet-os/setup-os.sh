#!/bin/bash
# Mega Pi 5 Tablet OS Installer
# Installs ALL dependencies for: RetroPie, TV Hat, SIM Hat, NVMe, Controllers

# --- Configuration ---
USER="pi"
RETROPIE_DIR="/mnt/retropie"  # NVMe storage
RETROPIE_HOME="/home/$USER/RetroPie"  # User-friendly access
DESKTOP_DIR="/home/$USER/Desktop"

# --- Helper Functions ---
red(){ echo -e "\033[31m$1\033[0m"; }
green(){ echo -e "\033[32m$1\033[0m"; }
blue(){ echo -e "\033[34m$1\033[0m"; }
abort(){ red "✗ $1"; exit 1; }
status(){ green "➜ $1"; }

# --- Hardware Verification ---
status "Verifying Raspberry Pi 5..."
grep -q "Raspberry Pi 5" /proc/device-tree/model || abort "This script requires Raspberry Pi 5"

status "Checking free space..."
MIN_SPACE=10000000  # 10GB minimum
FREE_SPACE=$(df / | awk 'NR==2 {print $4}')
[ "$FREE_SPACE" -ge "$MIN_SPACE" ] || abort "Need at least 10GB free space"

# --- Phase 1: Base System ---
status "\n=== INSTALLING CORE PACKAGES ==="
sudo apt update || abort "Failed to update packages"

# Essential system packages
sudo apt install -y \
    raspi-config rpi-update firmware-atheros \
    firmware-realtek firmware-ralink u-boot-rpi \
    linux-image-raspi linux-headers-raspi \
    build-essential pkg-config cmake || abort "Core packages failed"

# --- Phase 2: Hardware Support ---
status "\n=== SETTING UP HARDWARE ==="

# NVMe Storage
status "Configuring NVMe..."
sudo mkdir -p "$RETROPIE_DIR"
if ! grep -q "$RETROPIE_DIR" /etc/fstab; then
    sudo mkfs.ext4 -F /dev/nvme0n1p1 || abort "NVMe format failed"
    echo "/dev/nvme0n1p1 $RETROPIE_DIR ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab
    sudo mount -a || abort "NVMe mount failed"
fi

# TV Hat (DVB-T2)
status "Setting up TV Hat..."
sudo apt install -y \
    dvb-tools dvb-apps v4l-utils \
    ffmpeg w-scan libdvbv5-0 \
    libavcodec58 libavformat58 || abort "TV Hat packages failed"
echo "dtoverlay=dvb" | sudo tee -a /boot/config.txt

# SIM Hat (Cellular)
status "Setting up SIM Hat..."
sudo apt install -y \
    modemmanager mmcli usb-modeswitch \
    ppp wvdial chat || abort "SIM Hat packages failed"
sudo usermod -aG dialout "$USER"

# --- Phase 3: Multimedia ---
status "\n=== INSTALLING MULTIMEDIA ==="

# TV/Radio App Dependencies
sudo apt install -y \
    vlc rtl-sdr librtlsdr-dev \
    atsc-tools libatsc3-dev \
    pulseaudio pavucontrol || abort "Multimedia packages failed"

# Kivy GUI Framework
sudo apt install -y \
    libsdl2-dev libsdl2-image-dev \
    libsdl2-mixer-dev libsdl2-ttf-dev \
    python3-kivy python3-kivy-examples || abort "Kivy installation failed"

# --- Phase 4: Gaming ---
status "\n=== SETTING UP GAMING ==="

# RetroPie Dependencies
sudo apt install -y \
    libsdl2-dev libboost-all-dev \
    libfreeimage-dev libopenal-dev \
    libpugixml-dev libcurl4-openssl-dev \
    libasound2-dev libgl1-mesa-dev || abort "RetroPie dependencies failed"

# Xbox Controller Support
status "Adding Xbox controller support..."
sudo apt install -y \
    xboxdrv joystick jstest-gtk \
    evtest xpad xbox-one-controller || abort "Controller packages failed"

# Create udev rules
sudo tee /etc/udev/rules.d/99-xbox-controller.rules > /dev/null <<EOL
# Xbox Controller Rules
SUBSYSTEM=="input", ATTRS{idVendor}=="045e", MODE="0666"
EOL
sudo udevadm control --reload

# --- Phase 5: Install RetroPie ---
status "\n=== INSTALLING RETROPIE ==="
cd /home/"$USER" || abort "Couldn't access home directory"

if [ ! -d RetroPie-Setup ]; then
    git clone --depth=1 --branch=pi5 https://github.com/RetroPie/RetroPie-Setup.git || abort "Clone failed"
fi

cd RetroPie-Setup || abort "Couldn't enter setup directory"

# Custom configuration for NVMe
cat > configs/nvme.cfg <<EOL
romdir="$RETROPIE_DIR/roms"
biosdir="$RETROPIE_DIR/bios"
savedir="$RETROPIE_DIR/saves"
downloaddir="$RETROPIE_DIR/downloads"
EOL

# Run installer with Pi 5 optimizations
sudo ./retropie_setup.sh --module-cores $(nproc) --module-optimization pi5 || abort "RetroPie install failed"

# --- Phase 6: TV/Radio App Setup ---
status "\n=== SETTING UP TV/RADIO APP ==="

# Install Python dependencies
pip3 install --upgrade pip || abort "Pip upgrade failed"
pip3 install \
    pyrtlsdr pyudev dbus-python \
    python-dvbv5 || abort "Python packages failed"

# Create desktop shortcut for TV App
cat > "$DESKTOP_DIR/TV_Radio.desktop" <<EOL
[Desktop Entry]
Name=TV/Radio
Exec=python3 /home/$USER/tv_radio_app.py
Icon=/usr/share/icons/tv_icon.png
Type=Application
Categories=AudioVideo;
EOL

# Download TV icon
sudo wget -q https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/retropie.png -O /usr/share/icons/tv_icon.png

# --- Phase 7: Final Configuration ---
status "\n=== FINAL CONFIGURATION ==="

# Create user-friendly ROMs directory
mkdir -p "$RETROPIE_HOME"
ln -sf "$RETROPIE_DIR/roms" "$RETROPIE_HOME/roms" || abort "ROMs symlink failed"

# Set permissions
sudo chown -R "$USER:$USER" "$RETROPIE_DIR" "$RETROPIE_HOME"
chmod 755 "$DESKTOP_DIR"/*.desktop

# Performance tuning
status "Optimizing performance..."
echo "arm_boost=1" | sudo tee -a /boot/config.txt
echo "gpu_mem=1024" | sudo tee -a /boot/config.txt
echo "disable_overscan=1" | sudo tee -a /boot/config.txt

# --- Completion ---
status "\n=== INSTALLATION COMPLETE ==="
blue "\nAccess Options:"
echo "1. RetroPie: ~/RetroPie-Setup/retropie_setup.sh"
echo "2. TV/Radio: Desktop shortcut or 'python3 tv_radio_app.py'"
echo "3. ROMs: ~/RetroPie/roms (linked to NVMe)"

blue "\nRecommended Next Steps:"
echo "- Run 'sudo raspi-config' to:"
echo "  * Set GPU memory split (1024MB recommended)"
echo "  * Enable SPI/I2C for hardware hats"
echo "- Scan TV channels: 'w_scan -c GB -x > channels.conf'"
echo "- Configure cellular: 'sudo nmcli connection edit'"

# Reboot prompt
echo -e "\n\033[1;33mReboot recommended. Reboot now? (y/n)\033[0m"
read -r answer
if [[ "$answer" =~ ^[Yy] ]]; then
    sudo reboot
fi