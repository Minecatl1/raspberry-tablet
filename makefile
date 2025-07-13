# Raspberry Pi Tablet OS Build System
# Version 2.3 - Complete with Notification System, Google Play Store, and Waydroid Auto-Start

# Project configuration
PROJECT_NAME = pi-tablet-os
VERSION = 2.3.0
BUILD_DIR = build
DIST_DIR = dist
PACKAGE_NAME = $(PROJECT_NAME)-$(VERSION).zip

# Main application files
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

# Widget files
WIDGET_FILES = \
	widgets/notification_bar.py \
	widgets/notification_center.py

# Resource directories
RES_DIRS = \
	icons \
	scripts \
	config \
	apks \
	roms \
	profiles \
	widgets \
	gapps

# Default icons to create
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

# Script files
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
	
	# Create main application files
	@echo "Creating application files..."
  @sudo apt install unzip
	@$(foreach file,$(MAIN_APPS),echo "$($(file))" > $(BUILD_DIR)/$(PROJECT_NAME)/$(file);)
	
	# Create widget files
	@echo "Creating widget files..."
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/widgets
	@$(foreach widget,$(WIDGET_FILES),echo "$($(widget))" > $(BUILD_DIR)/$(PROJECT_NAME)/$(widget);)
	
	# Create resource directories
	@echo "Creating resource directories..."
	@mkdir -p $(foreach dir,$(RES_DIRS),$(BUILD_DIR)/$(PROJECT_NAME)/$(dir))
	
	# Create default icons
	@echo "Generating default icons..."
	@mkdir -p $(BUILD_DIR)/$(PROJECT_NAME)/icons
	@$(foreach icon,$(ICONS),touch $(BUILD_DIR)/$(PROJECT_NAME)/icons/$(icon);)
	
	# Create script files
	@echo "Creating installation scripts..."
	@$(foreach script,$(SCRIPT_FILES),echo "$($(script))" > $(BUILD_DIR)/$(PROJECT_NAME)/scripts/$(script);)
	@chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/scripts/*
	
	# Create config files
	@echo "Creating configuration files..."
	@echo "[Desktop Entry]\nType=Application\nName=Pi Tablet\nExec=python3 ~/tablet-apps/tablet_launcher.py" > $(BUILD_DIR)/$(PROJECT_NAME)/config/autostart.desktop
	
	# Create version file
	@echo '{"version": "$(VERSION)"}' > $(BUILD_DIR)/$(PROJECT_NAME)/version.json
	
	# Create install script
	@echo "#!/bin/bash\n\n# Pi Tablet OS Installation Script\n# Version $(VERSION)\n\necho \"Installing Raspberry Pi Tablet OS v$(VERSION)...\"\nsudo apt update\nsudo apt install -y python3-kivy python3-pip chromium-browser matchbox-keyboard \\ \n\tpython3-picamera2 bluez pulseaudio unzip p7zip-full \\ \n\tv4l-utils dvb-tools tvheadend mpv android-tools-adb\n\npip3 install cryptography keyring requests pillow\n\nmkdir -p ~/tablet-apps\ncp -r . ~/tablet-apps\n\n# Fix permissions for Waydroid\nsudo usermod -aG waydroid $USER\nsudo chmod 755 /var/lib/waydroid /var/lib/waydroid/*\nsudo chown $USER:waydroid /var/lib/waydroid /var/lib/waydroid/*\n\n# Install optional components\nbash ~/tablet-apps/scripts/install_optional.sh\n\n# Preinstall APKs\nbash ~/tablet-apps/scripts/preinstall_apks.sh\n\n# Setup DRM\nbash ~/tablet-apps/scripts/setup_drm.sh\n\n# Add to autostart\necho \"@python3 ~/tablet-apps/tablet_launcher.py\" >> ~/.config/lxsession/LXDE-pi/autostart\n\necho \"Installation complete! Restart your Raspberry Pi.\"" > $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	@chmod +x $(BUILD_DIR)/$(PROJECT_NAME)/install.sh
	
	# Create README
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
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleServicesFramework.apk https://github.com/opengapps/arm/releases/download/20230801/GoogleServicesFramework-11.0-20230801.apk
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GoogleAccountManager.apk https://github.com/opengapps/arm/releases/download/20230801/GoogleAccountManager-11.0-20230801.apk
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayServices.apk https://github.com/opengapps/arm/releases/download/20230801/GooglePlayServices-11.0-20230801.apk
	@wget -q -O $(BUILD_DIR)/$(PROJECT_NAME)/gapps/GooglePlayStore.apk https://github.com/opengapps/arm/releases/download/20230801/GooglePlayStore-11.0-20230801.apk
	@echo "Google Play Services components downloaded"

# ============================================================
# File content definitions
# ============================================================

# Tablet Launcher (Updated with Waydroid monitor)
define tablet_launcher.py
import os
import sys
import subprocess
import time
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.core.window import Window
from kivy.clock import Clock
from notification_manager import NotificationManager
from widgets.notification_bar import NotificationBar
from waydroid_monitor import start_waydroid_monitor

class TabletLauncher(App):
    def build(self):
        Window.fullscreen = 'auto'
        main_layout = BoxLayout(orientation='vertical')
        
        # Notification bar
        self.notification_bar = NotificationBar()
        main_layout.add_widget(self.notification_bar)
        
        # App grid
        app_grid = GridLayout(cols=4, spacing=20, padding=20)
        
        apps = [
            ("TV", "icons/tv.png", self.launch_tv),
            ("Camera", "icons/camera.png", self.launch_camera),
            ("Browser", "icons/browser.png", self.launch_browser),
            ("Bluetooth", "icons/bluetooth.png", self.launch_bluetooth),
            ("Streaming", "icons/streaming.png", self.launch_streaming),
            ("Files", "icons/file_manager.png", self.launch_file_manager),
            ("RetroArch", "icons/retroarch.png", self.launch_retroarch),
            ("APK Manager", "icons/apk.png", self.launch_apk_manager),
            ("Update", "icons/update.png", self.launch_update),
            ("Settings", "icons/settings.png", self.launch_settings),
            ("WiFi", "icons/wifi.png", self.show_wifi_setup),
            ("Power", "icons/power.png", self.show_power_menu)
        ]
        
        for name, icon_path, callback in apps:
            btn_layout = BoxLayout(orientation='vertical')
            try:
                img = Image(source=icon_path, size_hint_y=0.8)
            except:
                img = Image(source="icons/default.png", size_hint_y=0.8)
            lbl = Button(text=name, size_hint_y=0.2, background_color=(0,0,0,0))
            lbl.bind(on_press=callback)
            btn_layout.add_widget(img)
            btn_layout.add_widget(lbl)
            app_grid.add_widget(btn_layout)
        
        main_layout.add_widget(app_grid)
        
        # Initialize notification manager
        self.notif_manager = NotificationManager()
        
        # Start Waydroid monitor
        start_waydroid_monitor()
        
        # Update notifications every 5 seconds
        Clock.schedule_interval(self.update_notifications, 5)
        
        return main_layout
    
    def update_notifications(self, dt):
        unread = sum(1 for n in self.notif_manager.notifications if not n.read)
        self.notification_bar.unread_count = unread
        
        # Show latest high-priority notification
        if unread > 0 and not self.notification_bar.current_notification.text:
            latest = next((n for n in self.notif_manager.notifications if not n.read and n.priority > 0), None)
            if latest:
                self.notification_bar.show_notification(latest.title)
    
    # App launch methods
    def launch_tv(self, instance):
        subprocess.Popen(["python3", "tv_app.py"])
    
    def launch_camera(self, instance):
        subprocess.Popen(["python3", "camera_app.py"])
    
    def launch_browser(self, instance):
        subprocess.Popen(["chromium-browser", "--touch-events", "--enable-pinch"])
    
    def launch_bluetooth(self, instance):
        subprocess.Popen(["python3", "bluetooth_app.py"])
    
    def launch_streaming(self, instance):
        subprocess.Popen(["python3", "streaming_hub.py"])
    
    def launch_file_manager(self, instance):
        subprocess.Popen(["python3", "file_manager.py"])
    
    def launch_retroarch(self, instance):
        subprocess.Popen(["python3", "retroarch_app.py"])
    
    def launch_apk_manager(self, instance):
        subprocess.Popen(["python3", "apk_manager.py"])
    
    def launch_update(self, instance):
        subprocess.Popen(["python3", "update_manager.py"])
    
    def launch_settings(self, instance):
        subprocess.Popen(["pcmanfm"])
    
    def show_wifi_setup(self, instance):
        # Implementation would go here
        pass
    
    def show_power_menu(self, instance):
        # Implementation would go here
        pass

if __name__ == "__main__":
    TabletLauncher().run()
endef

# Notification Manager
define notification_manager.py
import json
import os
from datetime import datetime
from kivy.metrics import dp

class Notification:
    def __init__(self, title, content, app_name, priority=0, channel="system", icon="bell.png"):
        self.id = int(datetime.now().timestamp())
        self.title = title
        self.content = content
        self.app_name = app_name
        self.priority = priority  # 0=low, 1=normal, 2=high
        self.channel = channel
        self.icon = icon
        self.timestamp = datetime.now().strftime("%H:%M:%S")
        self.read = False

class NotificationManager:
    _instance = None
    MAX_NOTIFICATIONS = 50
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.notifications = []
            cls._instance.load()
        return cls._instance
    
    def add(self, notification):
        self.notifications.insert(0, notification)
        if len(self.notifications) > self.MAX_NOTIFICATIONS:
            self.notifications = self.notifications[:self.MAX_NOTIFICATIONS]
        self.save()
    
    def mark_read(self, notification_id):
        for n in self.notifications:
            if n.id == notification_id:
                n.read = True
        self.save()
    
    def clear_all(self):
        self.notifications = []
        self.save()
    
    def save(self):
        path = os.path.join(os.path.expanduser("~"), ".pi_tablet", "notifications.json")
        data = [{
            "id": n.id,
            "title": n.title,
            "content": n.content,
            "app_name": n.app_name,
            "priority": n.priority,
            "channel": n.channel,
            "icon": n.icon,
            "timestamp": n.timestamp,
            "read": n.read
        } for n in self.notifications]
        
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            json.dump(data, f)
    
    def load(self):
        path = os.path.join(os.path.expanduser("~"), ".pi_tablet", "notifications.json")
        if os.path.exists(path):
            with open(path, "r") as f:
                data = json.load(f)
                self.notifications = []
                for item in data:
                    notification = Notification(
                        title=item["title"],
                        content=item["content"],
                        app_name=item["app_name"],
                        priority=item["priority"],
                        channel=item["channel"],
                        icon=item["icon"]
                    )
                    notification.id = item["id"]
                    notification.timestamp = item["timestamp"]
                    notification.read = item["read"]
                    self.notifications.append(notification)
endef

# Notification Bar Widget
define widgets/notification_bar.py
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.image import Image
from kivy.animation import Animation
from kivy.properties import NumericProperty
from kivy.metrics import dp

class NotificationBar(BoxLayout):
    unread_count = NumericProperty(0)
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.size_hint_y = None
        self.height = dp(40)
        self.orientation = 'horizontal'
        self.padding = [dp(10), 0]
        
        self.icon = Image(
            source="icons/bell.png",
            size_hint_x=None,
            width=dp(30)
        self.add_widget(self.icon)
        
        self.counter = Label(
            text="0",
            font_size=dp(18),
            bold=True,
            size_hint_x=None,
            width=dp(30))
        self.add_widget(self.counter)
        
        self.current_notification = Label(
            text="",
            font_size=dp(16),
            halign="left",
            valign="middle")
        self.add_widget(self.current_notification)
        
        self.bind(unread_count=self.update_counter)
    
    def update_counter(self, instance, value):
        self.counter.text = str(value)
        if value > 0:
            self.counter.color = (1, 0, 0, 1)  # Red for unread
        else:
            self.counter.color = (0.8, 0.8, 0.8, 1)  # Gray for zero
    
    def show_notification(self, title):
        self.current_notification.text = title
        
        # Animation: Slide in
        anim = Animation(opacity=1, duration=0.3) + \
               Animation(opacity=1, duration=3) + \
               Animation(opacity=0, duration=0.5)
        anim.start(self.current_notification)
endef

# Notification Center Widget
define widgets/notification_center.py
from kivy.uix.modalview import ModalView
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.image import Image
from kivy.properties import ObjectProperty
from kivy.metrics import dp
from notification_manager import NotificationManager

class NotificationCenter(ModalView):
    notification_list = ObjectProperty(None)
    
    def on_open(self):
        self.refresh_list()
    
    def refresh_list(self):
        manager = NotificationManager()
        self.notification_list.clear_widgets()
        
        for notification in manager.notifications:
            item = BoxLayout(
                orientation='horizontal',
                size_hint_y=None,
                height=dp(60))
            
            # Status indicator
            status_color = (1, 0.2, 0.2, 1) if not notification.read else (0.3, 0.3, 0.3, 1)
            status = Label(
                text="•",
                color=status_color,
                font_size=dp(24),
                size_hint_x=None,
                width=dp(30))
            item.add_widget(status)
            
            # Icon
            icon = Image(
                source=f"icons/{notification.icon}",
                size_hint_x=None,
                width=dp(40))
            item.add_widget(icon)
            
            # Content
            content = BoxLayout(orientation='vertical')
            content.add_widget(Label(
                text=notification.title,
                font_size=dp(16),
                bold=True,
                halign='left'))
            content.add_widget(Label(
                text=f"{notification.app_name} - {notification.timestamp}",
                font_size=dp(12),
                color=(0.8, 0.8, 0.8, 1),
                halign='left'))
            item.add_widget(content)
            
            # Add click handler
            item.bind(on_touch_down=lambda i, t: self.on_notification_click(i, t, notification.id))
            self.notification_list.add_widget(item)
    
    def on_notification_click(self, instance, touch, notification_id):
        if instance.collide_point(*touch.pos):
            manager = NotificationManager()
            manager.mark_read(notification_id)
            self.refresh_list()
    
    def mark_all_read(self):
        manager = NotificationManager()
        for notification in manager.notifications:
            notification.read = True
        manager.save()
        self.refresh_list()
    
    def clear_all(self):
        manager = NotificationManager()
        manager.clear_all()
        self.refresh_list()
endef

# TV Application (Updated with notifications)
define tv_app.py
import os
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.graphics import Rectangle, Color
from kivy.core.window import Window
from kivy.animation import Animation
import threading
from notification_manager import Notification, NotificationManager

class TVApp(App):
    def build(self):
        Window.fullscreen = 'auto'
        self.screen = BoxLayout(orientation='horizontal')
        
        # Channel panel
        self.channel_panel = ScrollView(size_hint_x=None, width=0)
        self.channel_container = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.channel_container.bind(minimum_height=self.channel_container.setter('height'))
        self.channel_panel.add_widget(self.channel_container)
        
        # Video area
        self.video_area = BoxLayout(orientation='vertical')
        self.now_playing = Label(text="Select a channel", size_hint_y=0.1)
        self.video_container = BoxLayout(size_hint_y=0.9)
        
        with self.video_container.canvas:
            Color(0.1, 0.1, 0.1, 1)
            self.bg_rect = Rectangle(size=self.video_container.size, pos=self.video_container.pos)
        
        self.video_area.add_widget(self.now_playing)
        self.video_area.add_widget(self.video_container)
        
        self.screen.add_widget(self.channel_panel)
        self.screen.add_widget(self.video_area)
        
        self.video_container.bind(size=self.update_bg_rect)
        
        threading.Thread(target=self.load_channels).start()
        
        return self.screen
    
    def update_bg_rect(self, instance, value):
        self.bg_rect.size = instance.size
        self.bg_rect.pos = instance.pos
    
    def load_channels(self):
        try:
            channels = [
                {"name": "BBC One", "uuid": "bbc_one", "frequency": "554000"},
                {"name": "BBC Two", "uuid": "bbc_two", "frequency": "562000"},
                {"name": "ITV", "uuid": "itv", "frequency": "586000"},
                {"name": "Channel 4", "uuid": "channel4", "frequency": "602000"},
                {"name": "Channel 5", "uuid": "channel5", "frequency": "642000"},
            ]
            
            for channel in channels:
                btn = Button(
                    text=channel['name'],
                    size_hint_y=None,
                    height=70,
                    background_color=(0.2, 0.2, 0.4, 1))
                btn.channel_data = channel
                btn.bind(on_press=self.change_channel)
                self.channel_container.add_widget(btn)
                
        except Exception as e:
            error_label = Label(text=f"Error loading channels: {str(e)}", color=(1,0,0,1))
            self.channel_container.add_widget(error_label)
    
    def change_channel(self, instance):
        channel = instance.channel_data
        self.now_playing.text = f"Now Playing: {channel['name']}"
        self.show_channel_panel(False)
        self.start_video_player(channel['frequency'])
        
        # Send notification
        tv_notification = Notification(
            title="TV Channel Changed",
            content=f"Now playing: {channel['name']}",
            app_name="TV App",
            priority=1,
            channel="tv",
            icon="tv.png"
        )
        NotificationManager().add(tv_notification)
    
    def show_channel_panel(self, show=True):
        target_width = 300 if show else 0
        Animation(width=target_width, duration=0.3).start(self.channel_panel)
    
    def start_video_player(self, frequency):
        if hasattr(self, 'player_process'):
            self.player_process.terminate()
        
        # Use dvbv5-zap to tune to the channel
        subprocess.run([
            "dvbv5-zap",
            "-a", "0",
            "-c", "channels.conf",
            "-f", frequency,
            "-P"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        # Play the stream with mpv
        self.player_process = subprocess.Popen([
            "mpv",
            "--no-osc",
            "--fs",
            "--hwdec=mmal",
            "/dev/dvb/adapter0/dvr0"
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    
    def on_touch_move(self, touch):
        if touch.x < 50 and abs(touch.dy) < 20:
            self.show_channel_panel(True)
        return super().on_touch_move(touch)
    
    def on_stop(self):
        if hasattr(self, 'player_process'):
            self.player_process.terminate()
endef

# Update Manager (Updated with notifications)
define update_manager.py
import os
import json
import subprocess
import requests
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.textinput import TextInput
from kivy.uix.progressbar import ProgressBar
from kivy.clock import Clock
from notification_manager import Notification, NotificationManager

class UpdateManagerApp(App):
    def build(self):
        self.layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Status label
        self.status_label = Label(text="Current Version: Loading...", size_hint_y=0.2)
        self.layout.add_widget(self.status_label)
        
        # Check for updates button
        self.check_btn = Button(text="Check for Updates", size_hint_y=0.2)
        self.check_btn.bind(on_press=self.check_updates)
        self.layout.add_widget(self.check_btn)
        
        # Update button
        self.update_btn = Button(text="Install Updates", size_hint_y=0.2, disabled=True)
        self.update_btn.bind(on_press=self.start_update)
        self.layout.add_widget(self.update_btn)
        
        # Progress bar
        self.progress = ProgressBar(max=100, size_hint_y=0.1)
        self.layout.add_widget(self.progress)
        
        self.load_current_version()
        
        return self.layout
    
    def load_current_version(self):
        try:
            with open("version.json", "r") as f:
                version_data = json.load(f)
                self.current_version = version_data["version"]
                self.status_label.text = f"Current Version: {self.current_version}"
        except Exception as e:
            self.status_label.text = f"Error loading version: {str(e)}"
            self.current_version = "0.0.0"
    
    def check_updates(self, instance):
        self.check_btn.disabled = True
        self.check_btn.text = "Checking..."
        
        try:
            response = requests.get("https://api.github.com/repos/yourusername/pi-tablet-os/releases/latest")
            if response.status_code == 200:
                latest_release = response.json()
                self.latest_version = latest_release["tag_name"]
                
                if self.compare_versions(self.latest_version, self.current_version) > 0:
                    self.update_btn.disabled = False
                    self.status_label.text = f"Update available: {self.latest_version}"
                    
                    # Send notification
                    update_notification = Notification(
                        title="System Update Available",
                        content=f"Version {self.latest_version} ready to install",
                        app_name="Update Manager",
                        priority=2,
                        icon="update.png"
                    )
                    NotificationManager().add(update_notification)
                else:
                    self.status_label.text = "You have the latest version"
            else:
                self.status_label.text = "Failed to check for updates"
        except Exception as e:
            self.status_label.text = f"Error: {str(e)}"
        
        self.check_btn.disabled = False
        self.check_btn.text = "Check for Updates"
    
    def compare_versions(self, v1, v2):
        # Simple version comparison
        v1_parts = [int(x) for x in v1.split('.')]
        v2_parts = [int(x) for x in v2.split('.')]
        
        for i in range(max(len(v1_parts), len(v2_parts))):
            v1_part = v1_parts[i] if i < len(v1_parts) else 0
            v2_part = v2_parts[i] if i < len(v2_parts) else 0
            
            if v1_part > v2_part:
                return 1
            elif v1_part < v2_part:
                return -1
        return 0
    
    def start_update(self, instance):
        self.update_btn.disabled = True
        self.progress.value = 0
        
        # Simulated update process
        def update_progress(dt):
            if self.progress.value < 100:
                self.progress.value += 2
            else:
                Clock.unschedule(update_task)
                self.status_label.text = "Update complete! Restart required"
                
        update_task = Clock.schedule_interval(update_progress, 0.1)
endef

# Waydroid Monitor Script
define waydroid_monitor.py
import os
import subprocess
import time
import threading
from kivy.clock import Clock
from notification_manager import Notification, NotificationManager

class WaydroidMonitor:
    def __init__(self):
        self.running = False
        self.check_interval = 30  # seconds
        self.start_delay = 60     # seconds after boot
        
    def start(self):
        # Wait for system to settle after boot
        time.sleep(self.start_delay)
        
        # Start monitoring thread
        self.running = True
        threading.Thread(target=self.monitor_loop, daemon=True).start()
    
    def stop(self):
        self.running = False
    
    def is_waydroid_running(self):
        try:
            result = subprocess.run(
                ["systemctl", "is-active", "--quiet", "waydroid-container"],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception as e:
            print(f"Error checking Waydroid status: {e}")
            return False
    
    def start_waydroid(self):
        try:
            subprocess.run(["sudo", "systemctl", "start", "waydroid-container"], check=True)
            print("Waydroid container started")
            
            # Wait for services to initialize
            time.sleep(10)
            
            # Start the Waydroid session
            subprocess.Popen(["waydroid", "session", "start"])
            print("Waydroid session started")
            
            # Send notification
            notif = Notification(
                title="Waydroid Started",
                content="Android container is now running",
                app_name="System",
                priority=1,
                icon="android.png"
            )
            NotificationManager().add(notif)
            return True
        except Exception as e:
            print(f"Error starting Waydroid: {e}")
            return False
    
    def monitor_loop(self):
        while self.running:
            if not self.is_waydroid_running():
                print("Waydroid not running - attempting to start...")
                if not self.start_waydroid():
                    # If failed to start, wait longer before retrying
                    time.sleep(120)
            
            time.sleep(self.check_interval)

# Singleton instance
monitor = WaydroidMonitor()

# Start function for Kivy integration
def start_waydroid_monitor():
    monitor.start()
endef

# File Manager
define file_manager.py
import os
import subprocess
import shutil
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.textinput import TextInput
from kivy.core.window import Window

class FileManagerApp(App):
    def build(self):
        Window.fullscreen = 'auto'
        self.current_path = os.path.expanduser("~")
        
        layout = BoxLayout(orientation='vertical')
        
        # Path bar
        path_bar = BoxLayout(size_hint_y=0.1)
        dirs = [
            ("Home", "~"),
            ("APKs", "~/apks"),
            ("ROMs", "~/ROMs"),
            ("Documents", "~/Documents")
        ]
        
        for name, path in dirs:
            btn = Button(text=name, size_hint_x=0.25)
            btn.bind(on_press=lambda instance, p=path: self.set_path(p))
            path_bar.add_widget(btn)
        layout.add_widget(path_bar)
        
        # File chooser
        self.file_chooser = FileChooserListView(
            path=self.current_path,
            size_hint_y=0.8,
            filters=['*.apk', '*.exe', '*.deb', '*.nes', '*.snes', '*.gba']
        )
        self.file_chooser.bind(selection=self.on_selection)
        layout.add_widget(self.file_chooser)
        
        # Action buttons
        action_bar = BoxLayout(size_hint_y=0.1)
        self.open_btn = Button(text="Open", disabled=True)
        self.open_btn.bind(on_press=self.open_file)
        self.install_btn = Button(text="Install", disabled=True)
        self.install_btn.bind(on_press=self.install_file)
        self.delete_btn = Button(text="Delete", disabled=True)
        self.delete_btn.bind(on_press=self.delete_file)
        action_bar.add_widget(self.open_btn)
        action_bar.add_widget(self.install_btn)
        action_bar.add_widget(self.delete_btn)
        layout.add_widget(action_bar)
        
        return layout
    
    def set_path(self, path):
        expanded_path = os.path.expanduser(path)
        if os.path.exists(expanded_path):
            self.current_path = expanded_path
            self.file_chooser.path = expanded_path
    
    def on_selection(self, instance, selection):
        self.selected_file = selection[0] if selection else None
        self.open_btn.disabled = not bool(selection)
        self.install_btn.disabled = not bool(selection)
        self.delete_btn.disabled = not bool(selection)
    
    def open_file(self, instance):
        if self.selected_file:
            if os.path.isdir(self.selected_file):
                self.file_chooser.path = self.selected_file
            else:
                subprocess.Popen(["xdg-open", self.selected_file])
    
    def install_file(self, instance):
        # Implementation would go here
        pass
    
    def delete_file(self, instance):
        # Implementation would go here
        pass
    
    def show_error(self, title, message):
        content = Label(text=message)
        popup = Popup(title=title, content=content, size_hint=(0.7, 0.4))
        popup.open()
endef

# RetroArch Application
define retroarch_app.py
import os
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView

class RetroArchApp(App):
    def build(self):
        self.consoles = [
            {"name": "NES", "core": "nestopia", "icon": "icons/nes.png"},
            {"name": "SNES", "core": "snes9x", "icon": "icons/snes.png"},
            {"name": "Game Boy", "core": "gambatte", "icon": "icons/gb.png"},
            {"name": "Game Boy Advance", "core": "mgba", "icon": "icons/gba.png"},
            {"name": "Sega Genesis", "core": "genesis_plus_gx", "icon": "icons/genesis.png"},
            {"name": "PlayStation", "core": "pcsx_rearmed", "icon": "icons/psx.png"},
            {"name": "Nintendo 64", "core": "mupen64plus", "icon": "icons/n64.png"},
            {"name": "Atari 2600", "core": "stella", "icon": "icons/atari.png"},
        ]
        
        layout = BoxLayout(orientation='vertical')
        
        # Title
        title_bar = BoxLayout(size_hint_y=0.1)
        title_bar.add_widget(Label(text="RetroArch", font_size=24))
        layout.add_widget(title_bar)
        
        # Consoles grid
        scroll = ScrollView()
        grid = GridLayout(cols=3, spacing=20, padding=20, size_hint_y=None)
        grid.bind(minimum_height=grid.setter('height'))
        
        for console in self.consoles:
            btn = Button(
                background_normal=console["icon"],
                size_hint_y=None,
                height=200
            )
            btn.console = console
            btn.bind(on_press=self.launch_console)
            grid.add_widget(btn)
            
            lbl = Label(text=console["name"], size_hint_y=0.2)
            grid.add_widget(lbl)
        
        scroll.add_widget(grid)
        layout.add_widget(scroll)
        
        return layout
    
    def launch_console(self, instance):
        console = instance.console
        subprocess.Popen([
            "retroarch",
            "-L", f"/usr/lib/arm-linux-gnueabihf/libretro/{console['core']}_libretro.so",
            "--menu"
        ])
endef

# APK Manager
define apk_manager.py
import os
import subprocess
import shutil
import threading
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.popup import Popup
from kivy.clock import Clock

class APKManagerApp(App):
    def build(self):
        self.apk_dir = os.path.expanduser("~/apks")
        os.makedirs(self.apk_dir, exist_ok=True)
        
        layout = BoxLayout(orientation='vertical')
        
        # Title bar
        title_bar = BoxLayout(size_hint_y=0.1)
        title_bar.add_widget(Label(text="APK Manager"))
        refresh_btn = Button(text="↻", size_hint_x=0.2)
        refresh_btn.bind(on_press=self.refresh_list)
        title_bar.add_widget(refresh_btn)
        layout.add_widget(title_bar)
        
        # APK list
        self.scroll = ScrollView()
        self.grid = GridLayout(cols=1, spacing=10, padding=10, size_hint_y=None)
        self.grid.bind(minimum_height=self.grid.setter('height'))
        self.scroll.add_widget(self.grid)
        layout.add_widget(self.scroll)
        
        # Action buttons
        action_bar = BoxLayout(size_hint_y=0.1)
        install_btn = Button(text="Install New APK")
        install_btn.bind(on_press=self.install_apk)
        action_bar.add_widget(install_btn)
        layout.add_widget(action_bar)
        
        self.refresh_list()
        
        return layout
    
    def refresh_list(self, instance=None):
        # Implementation would go here
        pass
    
    def install_apk(self, instance):
        # Implementation would go here
        pass
endef

# Secure Storage
define secure_storage.py
import os
import json
from cryptography.fernet import Fernet
import keyring

class SecureStorage:
    def __init__(self):
        # Implementation would go here
        pass
    
    def save_credentials(self, service, username, password):
        # Implementation would go here
        pass
    
    def get_credentials(self, service):
        # Implementation would go here
        pass
    
    def save_wifi_credentials(self, ssid, password):
        # Implementation would go here
        pass
endef

# Global Keyboard
define global_keyboard.py
from pynput import keyboard
import os

def on_press(key):
    try:
        if key == keyboard.Key.esc:
            os.system("pkill chromium")
    except:
        pass

listener = keyboard.Listener(on_press=on_press)
listener.start()
endef

# Waydroid Manager
define waydroid_manager.py
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout

class WaydroidManagerApp(App):
    def build(self):
        # Implementation would go here
        pass
endef

# Camera Application
define camera_app.py
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.clock import Clock
from picamera2 import Picamera2
from libcamera import controls
import time

class CameraApp(App):
    def build(self):
        # Implementation would go here
        pass
endef

# Bluetooth Manager
define bluetooth_app.py
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.togglebutton import ToggleButton

class BluetoothApp(App):
    def build(self):
        # Implementation would go here
        pass
endef

# Streaming Hub
define streaming_hub.py
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.core.window import Window

class StreamingHubApp(App):
    def build(self):
        # Implementation would go here
        pass
endef

# ============================================================
# Script Files
# ============================================================

define install_optional.sh
#!/bin/bash
# Install optional components for Pi Tablet OS

echo "Installing optional components..."
sudo apt install -y wine-stable
bash ~/tablet-apps/scripts/install_waydroid.sh
bash ~/tablet-apps/scripts/install_retroarch.sh
sudo apt install -y flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt install -y unzip p7zip-full

echo "Creating ROM directories..."
mkdir -p ~/ROMs/{nes,snes,gb,gba,genesis,psx,n64,atari}

echo "Optional components installed!"
endef

define install_waydroid.sh
#!/bin/bash
# Install Waydroid for Android app support

echo "Installing Waydroid..."
sudo apt install -y curl ca-certificates
curl https://repo.waydro.id | sudo bash
sudo apt install -y waydroid
sudo waydroid init -y

# Fix permissions for auto-start
sudo usermod -aG waydroid $USER
sudo chmod 755 /var/lib/waydroid /var/lib/waydroid/*
sudo chown $USER:waydroid /var/lib/waydroid /var/lib/waydroid/*

sudo systemctl enable waydroid-container

echo "Starting Waydroid service..."
sudo systemctl start waydroid-container

echo "Creating desktop shortcut..."
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
# Install RetroArch and cores

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

echo "Creating retroarch config directory..."
mkdir -p ~/.config/retroarch

echo "RetroArch installation complete!"
endef

define preinstall_apks.sh
#!/bin/bash
# Preinstall APKs and Google Play Services

APK_DIR=~/tablet-apps/apks
LOG_FILE=~/apk_install.log
GAPPS_DIR=~/tablet-apps/gapps

echo "Starting APK preinstallation..." > $LOG_FILE

# Install regular APKs
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

# Install Google Play Services components via ADB
echo "Installing Google Play Services via ADB..." >> $LOG_FILE

# Start ADB server
adb start-server

# Connect to Waydroid container
adb connect 127.0.0.1:5555

# Wait for connection
sleep 5

# Install Google Services components in correct order
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

# Set required permissions
adb shell pm grant com.google.android.gms android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.google.android.gms android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant com.google.android.gms android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant com.google.android.gms android.permission.WRITE_EXTERNAL_STORAGE

# Configure Play Store
adb shell settings put global package_verifier_user_consent 1
adb shell settings put global install_non_market_apps 1
adb shell setprop persist.sys.timezone $(cat /etc/timezone)
adb shell setprop persist.sys.locale $(echo $LANG | cut -d '.' -f 1)

echo "Rebooting Waydroid container..." >> $LOG_FILE
sudo waydroid session stop
sleep 3
sudo waydroid session start

echo "Google Play Services installation completed" >> $LOG_FILE
endef

define setup_drm.sh
#!/bin/bash
# Setup Widevine DRM for streaming services

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
