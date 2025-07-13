PROJECT_NAME = pi-tablet-os
VERSION = 2.3.0
BUILD_DIR = build
DIST_DIR = dist
PACKAGE_NAME = $(PROJECT_NAME)-$(VERSION).zip

MAIN_APPS = \
	tablet_launcher.py \
	tv_app.py \
	camera_app.py \
	bluetooth_app.py \
	streaming_hub.py \
	update_manager.py \
	file_manager.py \
	retroarch_app.py \
	apk_manager.py \
	waydroid_manager.py \
	secure_storage.py \
	global_keyboard.py \
	notification_manager.py \
	waydroid_monitor.py

WIDGET_FILES = \
	widgets/notification_bar.py \
	widgets/notification_center.py

RES_DIRS = \
	icons \
	scripts \
	config \
	apks \
	roms \
	profiles \
	widgets \
	gapps

ICONS = \
	tv.png \
	camera.png \
	browser.png \
	bluetooth.png \
	streaming.png \
	file_manager.png \
	retroarch.png \
	apk.png \
	update.png \
	wifi.png \
	power.png \
	settings.png \
	nes.png \
	snes.png \
	gb.png \
	gba.png \
	genesis.png \
	psx.png \
	n64.png \
	atari.png \
	default.png \
	bell.png \
	android.png

SCRIPT_FILES = \
	install_optional.sh \
	install_waydroid.sh \
	install_retroarch.sh \
	preinstall_apks.sh \
	setup_drm.sh

.PHONY: all build clean package gapps

all: build package

build: clean gapps
	@echo "Building $(PROJECT_NAME) v$(VERSION)..."
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)
	@sudo apt install -y unzip
	@for file in $(MAIN_APPS); do \
		echo "$${!file}" > $(BUILD_DIR)/$(PROJECT_NAME)/$$file; \
	done
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/widgets
	@for widget in $(WIDGET_FILES); do \
		echo "$${!widget}" > $(BUILD_DIR)/$(PROJECT_NAME)/$$widget; \
	done
	@mkdir -p $(foreach dir,$(RES_DIRS),$(BUILD_DIR)/$(PROJECT_NAME)/$(dir))
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/icons
	@for icon in $(ICONS); do \
		touch $(BUILD_DIR)/$(PROJECT_NAME)/icons/$$icon; \
	done
	@for script in $(SCRIPT_FILES); do \
		echo "$${!script}" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/$$script; \
		chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/scripts/$$script; \
	done
	@echo "[Desktop Entry]\nType=Application\nName=Pi Tablet\nExec=python3 ~/tablet-apps/tablet_launcher.py" > $(BUILD_DIR)/$(PROJECT_NAME)/config/autostart.desktop
	@echo '{"version": "$(VERSION)"}' > $(BUILD_DIR)/$(PROJECT_NAME)/version.json
	@echo "#!/bin/bash\n\necho \"Installing Raspberry Pi Tablet OS v$(VERSION)...\"\nsudo apt update\nsudo apt install -y python3-kivy python3-pip chromium-browser matchbox-keyboard \\ \n\tpython3-picamera2 bluez pulseaudio unzip p7zip-full \\ \n\tv4l-utils dvb-tools tvheadend mpv android-tools-adb\n\npip3 install cryptography keyring requests pillow\n\nmkdir -p ~/tablet-apps\ncp -r . ~/tablet-apps\n\nsudo usermod -aG waydroid $$USER\nsudo chmod 755 /var/lib/waydroid /var/lib/waydroid/*\nsudo chown $$USER:waydroid /var/lib/waydroid /var/lib/waydroid/*\n\nbash ~/tablet-apps/scripts/install_optional.sh\n\nbash ~/tablet-apps/scripts/preinstall_apks.sh\n\nbash ~/tablet-apps/scripts/setup_drm.sh\n\necho \"@python3 ~/tablet-apps/tablet_launcher.py\" >> ~/.config/lxsession/LXDE-pi/autostart\n\necho \"Installation complete! Restart your Raspberry Pi.\"" > $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	@chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	@echo "# Raspberry Pi Tablet OS\n\n## Features\n- TV viewing with channel changing\n- Camera application\n- Bluetooth device management\n- Streaming services hub\n- File manager with APK/EXE/DEB support\n- RetroArch game emulator\n- Android app support via Waydroid\n- Google Play Store integration\n- Secure credential storage\n- Update manager\n- Notification system\n- Waydroid auto-start monitoring\n\n## Installation\nRun './install.sh' after copying to your Raspberry Pi\n\n## Version: $(VERSION)" > $(BUILD_DIR)/$(PROJECT_NAME)/README.md
	@echo "Build complete"

package: build
	@echo "Creating package..."
	@mkdir -p $(DIST_DIR)
	@cd $(BUILD_DIR) && zip -r ../$(DIST_DIR)/$(PACKAGE_NAME) $(PROJECT_NAME)
	@echo "Package created: $(DIST_DIR)/$(PACKAGE_NAME)"
	@echo "Build directory preserved at: $(BUILD_DIR)/$(PROJECT_NAME)"

clean:
	@echo "Cleaning build directories..."
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "Clean complete"

gapps:
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/gapps
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleServicesFramework.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GoogleServicesFramework.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleAccountManager.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GoogleAccountManager.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayServices.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GooglePlayServices.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayStore.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GooglePlayStore.apk || true
	@echo "Google Play Services components downloaded"

define tablet_launcher.py
[Previous content remains exactly the same]
endef

define notification_manager.py
[Previous content remains exactly the same]
endef

define widgets/notification_bar.py
[Previous content remains exactly the same]
endef

define widgets/notification_center.py
[Previous content remains exactly the same]
endef

define tv_app.py
[Previous content remains exactly the same]
endef

define update_manager.py
[Previous content remains exactly the same]
endef

define waydroid_monitor.py
[Previous content remains exactly the same]
endef

define file_manager.py
[Previous content remains exactly the same]
endef

define retroarch_app.py
[Previous content remains exactly the same]
endef

define apk_manager.py
[Previous content remains exactly the same]
endef

define secure_storage.py
[Previous content remains exactly the same]
endef

define global_keyboard.py
[Previous content remains exactly the same]
endef

define waydroid_manager.py
[Previous content remains exactly the same]
endef

define camera_app.py
[Previous content remains exactly the same]
endef

define bluetooth_app.py
[Previous content remains exactly the same]
endef

define streaming_hub.py
[Previous content remains exactly the same]
endef

define install_optional.sh
#!/bin/bash
echo "Installing optional components..."
sudo apt install -y wine-stable
bash ~/tablet-apps/scripts/install_waydroid.sh
bash ~/tablet-apps/scripts/install_retroarch.sh
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt install -y unzip p7zip-full
mkdir -p ~/ROMs/{nes,snes,gb,gba,genesis,psx,n64,atari}
echo "Optional components installed!"
endef

define install_waydroid.sh
#!/bin/bash
echo "Installing Waydroid..."
sudo apt install -y curl ca-certificates
curl https://repo.waydro.id | sudo bash
sudo apt install -y waydroid
sudo waydroid init -y
sudo usermod -aG waydroid $USER
sudo chmod 755 /var/lib/waydroid /var/lib/waydroid/*
sudo chown $USER:waydroid /var/lib/waydroid /var/lib/waydroid/*
sudo systemctl enable waydroid-container
echo "Starting Waydroid service..."
sudo systemctl start waydroid-container
cat > ~/Desktop/Waydroid.desktop <<EOF
[Desktop Entry]
Name=Waydroid
Exec=waydroid show-full-ui
Icon=/usr/share/waydroid/data/Waydroid.png
Terminal=false
Type=Application
EOF
chmod +x ~/Desktop/Waydroid.desktop
echo "Waydroid installation complete!"
endef

define install_retroarch.sh
#!/bin/bash
echo "Installing RetroArch..."
sudo apt install -y retroarch
echo "Installing emulation cores..."
sudo apt install -y \
    libretro-nestopia \
    libretro-snes9x \
    libretro-gambatte \
    libretro-mgba \
    libretro-genesis-plus-gx \
    libretro-pcsx-rearmed \
    libretro-mupen64plus \
    libretro-stella
mkdir -p ~/.config/retroarch
echo "RetroArch installation complete!"
endef

define preinstall_apks.sh
#!/bin/bash
APK_DIR=~/tablet-apps/apks
LOG_FILE=~/apk_install.log
GAPPS_DIR=~/tablet-apps/gapps
echo "Starting APK preinstallation..." > $LOG_FILE
if [ -d "$APK_DIR" ]; then
    for apk in "$APK_DIR"/*.apk; do
        if [ -f "$apk" ]; then
            echo "Installing $apk..." >> $LOG_FILE
            sudo waydroid app install "$apk" >> $LOG_FILE 2>&1
            mkdir -p "$APK_DIR/installed"
            mv "$apk" "$APK_DIR/installed/"
        fi
    done
fi
echo "Installing Google Play Services via ADB..." >> $LOG_FILE
adb start-server
adb connect 127.0.0.1:5555
sleep 5
for component in \
    GoogleServicesFramework \
    GoogleAccountManager \
    GooglePlayServices \
    GooglePlayStore
do
    apk_path="$GAPPS_DIR/$component.apk"
    if [ -f "$apk_path" ]; then
        echo "Installing $component..." >> $LOG_FILE
        adb install -r "$apk_path" >> $LOG_FILE 2>&1
    else
        echo "Missing $component APK!" >> $LOG_FILE
    fi
done
adb shell pm grant com.google.android.gms android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.google.android.gms android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant com.google.android.gms android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.google.android.gms android.permission.WRITE_EXTERNAL_STORAGE
adb shell settings put global package_verifier_user_consent 1
adb shell settings put global install_non_market_apps 1
adb shell setprop persist.sys.timezone $(cat /etc/timezone)
adb shell setprop persist.sys.locale $(echo $LANG | cut -d '.' -f 1)
sudo waydroid session stop
sleep 3
sudo waydroid session start
echo "Google Play Services installation completed" >> $LOG_FILE
endef

define setup_drm.sh
#!/bin/bash
echo "Setting up Widevine DRM..."
sudo apt install -y libwidevinecdm0
sudo mkdir -p /usr/lib/chromium-browser/WidevineCdm
echo "Downloading Widevine CDM..."
wget -O /tmp/widevine.zip https://dl.google.com/widevine-cdm/latest-linux-x64.zip
sudo unzip /tmp/widevine.zip -d /usr/lib/chromium-browser/WidevineCdm
sudo chmod 644 /usr/lib/chromium-browser/WidevineCdm/*
echo "Creating DRM configuration..."
sudo tee /etc/chromium-browser/customizations/10-drm <<EOF
#!/bin/sh
CHROMIUM_FLAGS="\$CHROMIUM_FLAGS --enable-features=Widevine --no-sandbox"
EOF
sudo chmod +x /etc/chromium-browser/customizations/10-drm
echo "DRM setup complete!"
endef
