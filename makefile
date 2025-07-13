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
	
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/widgets
	@mkdir -p $(foreach dir,$(RES_DIRS),$(BUILD_DIR)/$(PROJECT_NAME)/$(dir))
	
	@echo "Creating application files..."
	@echo "$(tablet_launcher_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/tablet_launcher.py
	@echo "$(tv_app_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/tv_app.py
	@echo "$(camera_app_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/camera_app.py
	@echo "$(streaming_hub_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/streaming_hub.py
	@echo "$(update_manager_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/update_manager.py
	@echo "$(file_manager_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/file_manager.py
	@echo "$(retroarch_app_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/retroarch_app.py
	@echo "$(apk_manager_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/apk_manager.py
	@echo "$(waydroid_manager_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/waydroid_manager.py
	@echo "$(secure_storage_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/secure_storage.py
	@echo "$(global_keyboard_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/global_keyboard.py
	@echo "$(waydroid_monitor_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/waydroid_monitor.py
	
	@echo "Creating widget files..."
	@echo "$(notification_bar_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/widgets/notification_bar.py
	@echo "$(notification_center_py)" > $(BUILD_DIR)/$(PROJECT_NAME)/widgets/notification_center.py
	
	@echo "Generating default icons..."
	@for icon in $(ICONS); do \
		touch $(BUILD_DIR)/$(PROJECT_NAME)/icons/$$icon; \
	done
	
	@echo "Creating installation scripts..."
	@echo "$(install_optional_sh)" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/install_optional.sh
	@echo "$(install_waydroid_sh)" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/install_waydroid.sh
	@echo "$(install_retroarch_sh)" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/install_retroarch.sh
	@echo "$(preinstall_apks_sh)" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/preinstall_apks.sh
	@echo "$(setup_drm_sh)" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/setup_drm.sh
	@chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/scripts/*
	
	@echo "Creating config files..."
	@echo "[Desktop Entry]\nType=Application\nName=Pi Tablet\nExec=python3 ~/tablet-apps/tablet_launcher.py" > $(BUILD_DIR)/$(PROJECT_NAME)/config/autostart.desktop
	@echo '{"version": "$(VERSION)"}' > $(BUILD_DIR)/$(PROJECT_NAME)/version.json
	
	@echo "Creating install script..."
	@echo "#!/bin/bash\n\necho \"Installing Raspberry Pi Tablet OS v$(VERSION)...\"\nsudo apt update\nsudo apt install -y python3-kivy python3-pip chromium-browser matchbox-keyboard \\ \n\tpython3-picamera2 bluez pulseaudio unzip p7zip-full \\ \n\tv4l-utils dvb-tools tvheadend mpv android-tools-adb\n\npip3 install cryptography keyring requests pillow\n\nmkdir -p ~/tablet-apps\ncp -r . ~/tablet-apps\n\nsudo usermod -aG waydroid \$$USER\nsudo chmod 755 /var/lib/waydroid /var/lib/waydroid/*\nsudo chown \$$USER:waydroid /var/lib/waydroid /var/lib/waydroid/*\n\nbash ~/tablet-apps/scripts/install_optional.sh\n\nbash ~/tablet-apps/scripts/preinstall_apks.sh\n\nbash ~/tablet-apps/scripts/setup_drm.sh\n\necho \"@python3 ~/tablet-apps/tablet_launcher.py\" >> ~/.config/lxsession/LXDE-pi/autostart\n\necho \"Installation complete! Restart your Raspberry Pi.\"" > $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	@chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	
	@echo "Creating README..."
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
	@echo "Downloading Google Play Services components..."
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleServicesFramework.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GoogleServicesFramework.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleAccountManager.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GoogleAccountManager.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayServices.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GooglePlayServices.apk || true
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayStore.apk https://github.com/Minecatl1/raspberry-tablet/releases/download/Google/GooglePlayStore.apk || true
	@echo "Google Play Services components downloaded"

define tablet_launcher_py
[Full tablet_launcher.py content here]
endef

define tv_app_py
[Full tv_app.py content here]
endef


define setup_drm_sh
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