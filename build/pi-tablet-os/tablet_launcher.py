import os
import sys
import subprocess
import time
import json
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.button import Button
from kivy.uix.image import AsyncImage
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.scrollview import ScrollView
from kivy.uix.screenmanager import ScreenManager, Screen, FadeTransition
from kivy.uix.textinput import TextInput
from kivy.uix.togglebutton import ToggleButton
from kivy.core.window import Window
from kivy.clock import Clock, mainthread
from kivy.properties import (StringProperty, NumericProperty, ObjectProperty, 
                           ListProperty, BooleanProperty, DictProperty)
from kivy.metrics import dp
from kivy.storage.jsonstore import JsonStore
import webbrowser
import dbus
import dbus.mainloop.glib
from functools import partial

# Configuration storage
CONFIG_DIR = os.path.expanduser("~/.tablet_launcher")
os.makedirs(CONFIG_DIR, exist_ok=True)

class AppButton(Button):
    icon_source = StringProperty("icons/default.png")
    app_name = StringProperty("App")

class WiFiNetworkButton(ToggleButton):
    ssid = StringProperty()
    strength = NumericProperty()
    secured = BooleanProperty()
    connected = BooleanProperty(False)

class BluetoothDeviceButton(ToggleButton):
    device_name = StringProperty()
    mac_address = StringProperty()
    connected = BooleanProperty(False)
    paired = BooleanProperty(False)

class NotificationBar(BoxLayout):
    unread_count = NumericProperty(0)
    current_notification = StringProperty("")
    wifi_status = BooleanProperty(False)
    bluetooth_status = BooleanProperty(False)
    battery_level = NumericProperty(100)
    time_text = StringProperty("00:00")

    def __init__(self, **kwargs):
        super(NotificationBar, self).__init__(**kwargs)
        self.orientation = 'horizontal'
        self.size_hint_y = None
        self.height = dp(40)
        self.padding = [dp(10), 0]
        self.spacing = dp(10)
        
        # Time
        self.time_label = Label(text=self.time_text, size_hint_x=None, width=dp(80))
        self.add_widget(self.time_label)
        
        # Notification area
        self.notification_label = Label(text=self.current_notification, halign='left', size_hint_x=1)
        self.add_widget(self.notification_label)
        
        # Status icons
        status_layout = BoxLayout(size_hint_x=None, width=dp(120), spacing=dp(5))
        
        self.wifi_icon = Label(text="[color=00ff00]WiFi[/color]" if self.wifi_status else "[color=ff0000]WiFi[/color]",
                             markup=True)
        self.bluetooth_icon = Label(text="[color=00ff00]BT[/color]" if self.bluetooth_status else "[color=ff0000]BT[/color]",
                                  markup=True)
        self.battery_icon = Label(text=f"[color=ffffff]{self.battery_level}%[/color]", markup=True)
        
        status_layout.add_widget(self.wifi_icon)
        status_layout.add_widget(self.bluetooth_icon)
        status_layout.add_widget(self.battery_icon)
        self.add_widget(status_layout)
        
        self.bind(wifi_status=self.update_wifi_icon)
        self.bind(bluetooth_status=self.update_bluetooth_icon)
        self.bind(battery_level=self.update_battery_icon)
        self.bind(time_text=self.time_label.setter('text'))
        self.bind(current_notification=self.notification_label.setter('text'))
        
        # Update time every minute
        Clock.schedule_interval(self.update_time, 60)
        self.update_time()
        
        # Simulate battery updates
        Clock.schedule_interval(self.update_battery, 300)
    
    def update_time(self, *args):
        from datetime import datetime
        self.time_text = datetime.now().strftime("%H:%M")
    
    def update_battery(self, *args):
        try:
            # Try to read actual battery level
            with open('/sys/class/power_supply/BAT0/capacity', 'r') as f:
                self.battery_level = int(f.read().strip())
        except:
            # Simulate battery drain if not available
            self.battery_level = max(0, self.battery_level - 2)
            if self.battery_level <= 10:
                self.current_notification = "Low battery!"
    
    def update_wifi_icon(self, *args):
        self.wifi_icon.text = "[color=00ff00]WiFi[/color]" if self.wifi_status else "[color=ff0000]WiFi[/color]"
    
    def update_bluetooth_icon(self, *args):
        self.bluetooth_icon.text = "[color=00ff00]BT[/color]" if self.bluetooth_status else "[color=ff0000]BT[/color]"
    
    def update_battery_icon(self, *args):
        color = "00ff00" if self.battery_level > 30 else "ffff00" if self.battery_level > 10 else "ff0000"
        self.battery_icon.text = f"[color={color}]{self.battery_level}%[/color]"
    
    def show_notification(self, text):
        self.current_notification = text
        Clock.schedule_once(self.clear_notification, 5)
    
    def clear_notification(self, dt):
        self.current_notification = ""

class WiFiSetupPopup(Popup):
    def __init__(self, app, **kwargs):
        super(WiFiSetupPopup, self).__init__(**kwargs)
        self.app = app
        self.title = "WiFi Networks"
        self.size_hint = (0.9, 0.8)
        
        layout = BoxLayout(orientation='vertical', spacing=dp(10))
        
        # Refresh button
        top_bar = BoxLayout(size_hint_y=0.1)
        refresh_btn = Button(text="Refresh")
        refresh_btn.bind(on_press=lambda x: self.app.scan_wifi())
        top_bar.add_widget(refresh_btn)
        layout.add_widget(top_bar)
        
        # Network list
        self.network_scroll = ScrollView()
        self.network_list = GridLayout(cols=1, spacing=dp(5), size_hint_y=None)
        self.network_list.bind(minimum_height=self.network_list.setter('height'))
        self.network_scroll.add_widget(self.network_list)
        layout.add_widget(self.network_scroll)
        
        # Password input
        self.password_input = TextInput(
            hint_text="Password", 
            password=True,
            size_hint_y=0.15,
            multiline=False
        )
        layout.add_widget(self.password_input)
        
        # Connect button
        self.connect_btn = Button(
            text="Connect", 
            size_hint_y=0.15,
            disabled=True
        )
        self.connect_btn.bind(on_press=self.connect_to_network)
        layout.add_widget(self.connect_btn)
        
        # Forget button
        self.forget_btn = Button(
            text="Forget Network",
            size_hint_y=0.15,
            disabled=True
        )
        self.forget_btn.bind(on_press=self.forget_network)
        layout.add_widget(self.forget_btn)
        
        self.content = layout
        self.app.scan_wifi()
    
    def connect_to_network(self, instance):
        selected = None
        for child in self.network_list.children:
            if child.state == 'down':
                selected = child
                break
        
        if selected:
            password = self.password_input.text if selected.secured else ""
            self.app.connect_wifi(selected.ssid, password)
            self.dismiss()
    
    def forget_network(self, instance):
        selected = None
        for child in self.network_list.children:
            if child.state == 'down':
                selected = child
                break
        
        if selected:
            self.app.forget_wifi(selected.ssid)
            self.app.scan_wifi()

class BluetoothSetupPopup(Popup):
    def __init__(self, app, **kwargs):
        super(BluetoothSetupPopup, self).__init__(**kwargs)
        self.app = app
        self.title = "Bluetooth Devices"
        self.size_hint = (0.9, 0.8)
        
        layout = BoxLayout(orientation='vertical', spacing=dp(10))
        
        # Top controls
        top_bar = BoxLayout(size_hint_y=0.1)
        scan_btn = Button(text="Scan")
        scan_btn.bind(on_press=lambda x: self.app.scan_bluetooth())
        toggle_btn = Button(text="Toggle Bluetooth")
        toggle_btn.bind(on_press=lambda x: self.app.toggle_bluetooth())
        top_bar.add_widget(scan_btn)
        top_bar.add_widget(toggle_btn)
        layout.add_widget(top_bar)
        
        # Device list
        self.device_scroll = ScrollView()
        self.device_list = GridLayout(cols=1, spacing=dp(5), size_hint_y=None)
        self.device_list.bind(minimum_height=self.device_list.setter('height'))
        self.device_scroll.add_widget(self.device_list)
        layout.add_widget(self.device_scroll)
        
        # Connect/Disconnect button
        self.connection_btn = Button(
            text="Connect", 
            size_hint_y=0.15,
            disabled=True
        )
        self.connection_btn.bind(on_press=self.toggle_connection)
        layout.add_widget(self.connection_btn)
        
        # Forget button
        self.forget_btn = Button(
            text="Forget Device",
            size_hint_y=0.15,
            disabled=True
        )
        self.forget_btn.bind(on_press=self.forget_device)
        layout.add_widget(self.forget_btn)
        
        self.content = layout
        self.app.scan_bluetooth()
    
    def toggle_connection(self, instance):
        selected = None
        for child in self.device_list.children:
            if child.state == 'down':
                selected = child
                break
        
        if selected:
            if selected.connected:
                self.app.disconnect_bluetooth(selected.mac_address)
            else:
                self.app.connect_bluetooth(selected.mac_address)
    
    def forget_device(self, instance):
        selected = None
        for child in self.device_list.children:
            if child.state == 'down':
                selected = child
                break
        
        if selected:
            self.app.forget_bluetooth(selected.mac_address)
            self.app.scan_bluetooth()

class HomeScreen(Screen):
    def __init__(self, **kwargs):
        super(HomeScreen, self).__init__(**kwargs)
        self.app = kwargs.get('app')
        
        main_layout = BoxLayout(orientation='vertical')
        
        # Notification bar
        self.notification_bar = NotificationBar()
        main_layout.add_widget(self.notification_bar)
        
        # App grid with scroll
        scroll = ScrollView()
        app_grid = GridLayout(cols=4, spacing=dp(15), padding=dp(15), size_hint_y=None)
        app_grid.bind(minimum_height=app_grid.setter('height'))
        
        apps = [
            ("TV", "icons/tv.png", self.app.launch_tv),
            ("Camera", "icons/camera.png", self.app.launch_camera),
            ("Browser", "icons/browser.png", self.app.launch_browser),
            ("Bluetooth", "icons/bluetooth.png", self.app.show_bluetooth_setup),
            ("Streaming", "icons/streaming.png", self.app.launch_streaming),
            ("Files", "icons/file_manager.png", self.app.launch_file_manager),
            ("RetroArch", "icons/retroarch.png", self.app.launch_retroarch),
            ("APK Manager", "icons/apk.png", self.app.launch_apk_manager),
            ("Update", "icons/update.png", self.app.launch_update),
            ("Settings", "icons/settings.png", self.app.launch_settings),
            ("WiFi", "icons/wifi.png", self.app.show_wifi_setup),
            ("Power", "icons/power.png", self.app.show_power_menu)
        ]
        
        for name, icon_path, callback in apps:
            btn = AppButton(
                icon_source=icon_path,
                app_name=name,
                size_hint=(None, None),
                size=(dp(100), dp(120)),
                on_press=callback
            )
            app_grid.add_widget(btn)
        
        scroll.add_widget(app_grid)
        main_layout.add_widget(scroll)
        
        # Add a dock for frequently used apps
        dock = BoxLayout(size_hint_y=0.15, spacing=dp(10), padding=dp(10))
        dock_apps = [
            ("Browser", "icons/browser.png", self.app.launch_browser),
            ("Camera", "icons/camera.png", self.app.launch_camera),
            ("Files", "icons/file_manager.png", self.app.launch_file_manager),
            ("Settings", "icons/settings.png", self.app.launch_settings)
        ]
        
        for name, icon_path, callback in dock_apps:
            btn = AppButton(
                icon_source=icon_path,
                app_name=name,
                size_hint=(None, None),
                size=(dp(80), dp(80)),
                on_press=callback
            )
            dock.add_widget(btn)
        
        main_layout.add_widget(dock)
        self.add_widget(main_layout)

class TabletLauncher(App):
    wifi_networks = ListProperty()
    bluetooth_devices = ListProperty()
    store = ObjectProperty()
    
    def build(self):
        Window.fullscreen = 'auto'
        Window.bind(on_keyboard=self._handle_keyboard)
        
        # Initialize storage
        self.store = JsonStore(os.path.join(CONFIG_DIR, 'config.json'))
        
        # Initialize WiFi and Bluetooth
        self.init_wifi()
        self.init_bluetooth()
        
        # Screen manager for home/app drawer
        self.sm = ScreenManager(transition=FadeTransition())
        
        # Initialize screens
        self.home_screen = HomeScreen(name='home', app=self)
        
        self.sm.add_widget(self.home_screen)
        
        # Initialize notification manager
        self.notif_manager = {
            'notifications': [],
            'add_notification': self.add_notification
        }
        
        # Check WiFi and Bluetooth status periodically
        Clock.schedule_interval(self.check_network_status, 10)
        
        # Initial status check
        self.check_network_status()
        
        return self.sm
    
    def _handle_keyboard(self, window, key, *args):
        if key == 27:  # ESC key
            return True
        return False
    
    def init_wifi(self):
        # Load saved networks
        if 'wifi_networks' not in self.store:
            self.store.put('wifi_networks', networks={})
        
        # Connect to known networks on startup
        known_networks = self.store.get('wifi_networks')['networks']
        for ssid, config in known_networks.items():
            if config.get('auto_connect', False):
                self.connect_wifi(ssid, config['password'])
    
    def init_bluetooth(self):
        # Load saved devices
        if 'bluetooth_devices' not in self.store:
            self.store.put('bluetooth_devices', devices={})
        
        # Try to reconnect to paired devices
        paired_devices = self.store.get('bluetooth_devices')['devices']
        for mac, config in paired_devices.items():
            if config.get('auto_connect', False):
                self.connect_bluetooth(mac)
    
    def scan_wifi(self):
        try:
            # This requires running as root or with proper permissions
            result = subprocess.run(
                ['sudo', 'iwlist', 'wlan0', 'scan'],
                capture_output=True,
                text=True
            )
            
            networks = []
            current_network = {}
            
            for line in result.stdout.split('\n'):
                line = line.strip()
                if 'Cell' in line and current_network:
                    networks.append(current_network)
                    current_network = {}
                elif 'ESSID:' in line:
                    current_network['ssid'] = line.split('ESSID:"')[1].rstrip('"')
                elif 'Quality=' in line:
                    parts = line.split('Quality=')
                    quality = parts[1].split(' ')[0]
                    current_network['strength'] = int(quality.split('/')[0])
                elif 'Encryption key:' in line:
                    current_network['secured'] = 'on' in line
            
            if current_network:
                networks.append(current_network)
            
            self.update_wifi_list(networks)
            
        except Exception as e:
            print(f"WiFi scan error: {e}")
            self.add_notification("WiFi Error", "Failed to scan networks", 2)
    
    @mainthread
    def update_wifi_list(self, networks):
        if hasattr(self, 'wifi_popup') and self.wifi_popup:
            self.wifi_popup.network_list.clear_widgets()
            
            # Sort by signal strength
            networks.sort(key=lambda x: x.get('strength', 0), reverse=True)
            
            # Get current connected network
            current_ssid = None
            try:
                result = subprocess.run(['iwgetid', '-r'], capture_output=True, text=True)
                if result.returncode == 0:
                    current_ssid = result.stdout.strip()
            except:
                pass
            
            # Get known networks
            known_networks = self.store.get('wifi_networks')['networks']
            
            for network in networks:
                ssid = network.get('ssid', 'Hidden Network')
                btn = WiFiNetworkButton(
                    text=f"{ssid} ({network.get('strength', 0)}%)",
                    ssid=ssid,
                    strength=network.get('strength', 0),
                    secured=network.get('secured', False),
                    connected=(ssid == current_ssid),
                    size_hint_y=None,
                    height=dp(50)
                )
                btn.bind(state=partial(self.on_wifi_selected, ssid))
                self.wifi_popup.network_list.add_widget(btn)
    
    def on_wifi_selected(self, ssid, instance, value):
        if hasattr(self, 'wifi_popup') and self.wifi_popup:
            if value == 'down':
                known_networks = self.store.get('wifi_networks')['networks']
                if ssid in known_networks:
                    self.wifi_popup.password_input.text = known_networks[ssid].get('password', '')
                self.wifi_popup.connect_btn.disabled = False
                self.wifi_popup.forget_btn.disabled = False
    
    def connect_wifi(self, ssid, password):
        try:
            # Create wpa_supplicant configuration
            config = f"""
            network={{
                ssid="{ssid}"
                psk="{password}"
                key_mgmt=WPA-PSK
            }}
            """
            
            # Save to temporary file
            with open('/tmp/wpa_temp.conf', 'w') as f:
                f.write(config)
            
            # Stop any existing wpa_supplicant
            subprocess.run(['sudo', 'killall', 'wpa_supplicant'], stderr=subprocess.DEVNULL)
            
            # Apply configuration
            subprocess.run([
                'sudo', 'wpa_supplicant', 
                '-B', '-i', 'wlan0', 
                '-c', '/tmp/wpa_temp.conf'
            ])
            
            # Request DHCP
            subprocess.run(['sudo', 'dhclient', 'wlan0'])
            
            # Save network for future use
            networks = self.store.get('wifi_networks')['networks']
            networks[ssid] = {
                'password': password,
                'auto_connect': True,
                'last_connected': time.time()
            }
            self.store.put('wifi_networks', networks=networks)
            
            self.add_notification(
                "WiFi Connected",
                f"Connected to {ssid}",
                1
            )
            
            # Update status
            self.check_network_status()
            
        except Exception as e:
            print(f"WiFi connection error: {e}")
            self.add_notification(
                "WiFi Error",
                f"Failed to connect to {ssid}",
                2
            )
    
    def forget_wifi(self, ssid):
        try:
            networks = self.store.get('wifi_networks')['networks']
            if ssid in networks:
                del networks[ssid]
                self.store.put('wifi_networks', networks=networks)
            
            self.add_notification(
                "WiFi Forgotten",
                f"Removed {ssid} from known networks",
                1
            )
            
            return True
        except Exception as e:
            print(f"Forget WiFi error: {e}")
            return False
    
    def scan_bluetooth(self):
        try:
            # Start bluetooth discovery
            subprocess.run(['sudo', 'bluetoothctl', 'scan', 'on'])
            time.sleep(5)  # Allow some time for discovery
            
            # Get list of devices
            result = subprocess.run(
                ['sudo', 'bluetoothctl', 'devices'],
                capture_output=True,
                text=True
            )
            
            devices = []
            for line in result.stdout.split('\n'):
                if line.strip():
                    parts = line.split()
                    mac = parts[1]
                    name = ' '.join(parts[2:])
                    devices.append({'mac': mac, 'name': name})
            
            self.update_bluetooth_list(devices)
            
        except Exception as e:
            print(f"Bluetooth scan error: {e}")
            self.add_notification("Bluetooth Error", "Failed to scan devices", 2)
    
    @mainthread
    def update_bluetooth_list(self, devices):
        if hasattr(self, 'bluetooth_popup') and self.bluetooth_popup:
            self.bluetooth_popup.device_list.clear_widgets()
            
            # Get paired devices from storage
            paired_devices = self.store.get('bluetooth_devices')['devices']
            
            # Get connected devices
            connected_devices = []
            try:
                result = subprocess.run(
                    ['sudo', 'bluetoothctl', 'info'],
                    capture_output=True,
                    text=True
                )
                for line in result.stdout.split('\n'):
                    if 'Device' in line and 'Connected: yes' in line:
                        mac = line.split('Device ')[1].split(' ')[0]
                        connected_devices.append(mac)
            except:
                pass
            
            for device in devices:
                mac = device['mac']
                name = device['name'] or mac
                is_paired = mac in paired_devices
                is_connected = mac in connected_devices
                
                btn = BluetoothDeviceButton(
                    text=f"{name} ({'Paired' if is_paired else 'Available'})",
                    device_name=name,
                    mac_address=mac,
                    connected=is_connected,
                    paired=is_paired,
                    size_hint_y=None,
                    height=dp(50)
                )
                btn.bind(state=partial(self.on_bluetooth_device_selected, mac))
                self.bluetooth_popup.device_list.add_widget(btn)
    
    def on_bluetooth_device_selected(self, mac, instance, value):
        if hasattr(self, 'bluetooth_popup') and self.bluetooth_popup:
            if value == 'down':
                self.bluetooth_popup.connection_btn.disabled = False
                self.bluetooth_popup.forget_btn.disabled = not instance.paired
                self.bluetooth_popup.connection_btn.text = (
                    "Disconnect" if instance.connected else "Connect"
                )
    
    def connect_bluetooth(self, mac_address):
        try:
            # Pair if not already paired
            paired_devices = self.store.get('bluetooth_devices')['devices']
            if mac_address not in paired_devices:
                # Pair the device
                subprocess.run(['sudo', 'bluetoothctl', 'pair', mac_address], timeout=30)
                paired_devices[mac_address] = {
                    'auto_connect': True,
                    'connected': False
                }
                self.store.put('bluetooth_devices', devices=paired_devices)
                time.sleep(2)
            
            # Connect
            subprocess.run(['sudo', 'bluetoothctl', 'connect', mac_address], timeout=30)
            
            # Update status
            paired_devices = self.store.get('bluetooth_devices')['devices']
            paired_devices[mac_address]['connected'] = True
            paired_devices[mac_address]['last_connected'] = time.time()
            self.store.put('bluetooth_devices', devices=paired_devices)
            
            self.add_notification(
                "Bluetooth Connected",
                f"Connected to device",
                1
            )
            
            # Refresh list
            self.scan_bluetooth()
            
        except subprocess.TimeoutExpired:
            self.add_notification(
                "Bluetooth Error",
                "Pairing/connection timed out",
                2
            )
        except Exception as e:
            print(f"Bluetooth connection error: {e}")
            self.add_notification(
                "Bluetooth Error",
                "Failed to connect to device",
                2
            )
    
    def disconnect_bluetooth(self, mac_address):
        try:
            subprocess.run(['sudo', 'bluetoothctl', 'disconnect', mac_address])
            
            # Update status
            paired_devices = self.store.get('bluetooth_devices')['devices']
            paired_devices[mac_address]['connected'] = False
            self.store.put('bluetooth_devices', devices=paired_devices)
            
            self.add_notification(
                "Bluetooth Disconnected",
                "Device disconnected",
                1
            )
            
            # Refresh list
            self.scan_bluetooth()
            
        except Exception as e:
            print(f"Bluetooth disconnection error: {e}")
            self.add_notification(
                "Bluetooth Error",
                "Failed to disconnect device",
                2
            )
    
    def forget_bluetooth(self, mac_address):
        try:
            # Remove pairing
            subprocess.run(['sudo', 'bluetoothctl', 'remove', mac_address])
            
            # Update storage
            paired_devices = self.store.get('bluetooth_devices')['devices']
            if mac_address in paired_devices:
                del paired_devices[mac_address]
                self.store.put('bluetooth_devices', devices=paired_devices)
            
            self.add_notification(
                "Bluetooth Forgotten",
                "Device removed",
                1
            )
            
            return True
        except Exception as e:
            print(f"Forget Bluetooth error: {e}")
            return False
    
    def toggle_bluetooth(self):
        try:
            result = subprocess.run(
                ['sudo', 'bluetoothctl', 'show'],
                capture_output=True,
                text=True
            )
            
            powered = 'Powered: yes' in result.stdout
            
            subprocess.run([
                'sudo', 'bluetoothctl', 
                'power', 'off' if powered else 'on'
            ])
            
            self.add_notification(
                "Bluetooth",
                f"Bluetooth turned {'off' if powered else 'on'}",
                1
            )
            
            # Refresh list
            self.scan_bluetooth()
            
        except Exception as e:
            print(f"Bluetooth toggle error: {e}")
            self.add_notification(
                "Bluetooth Error",
                "Failed to toggle Bluetooth",
                2
            )
    
    def check_network_status(self, dt=None):
        # Check WiFi status
        try:
            result = subprocess.run(
                ['iwgetid'],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                self.home_screen.notification_bar.wifi_status = True
            else:
                self.home_screen.notification_bar.wifi_status = False
        except:
            self.home_screen.notification_bar.wifi_status = False
        
        # Check Bluetooth status
        try:
            result = subprocess.run(
                ['sudo', 'bluetoothctl', 'show'],
                capture_output=True,
                text=True
            )
            
            self.home_screen.notification_bar.bluetooth_status = (
                'Powered: yes' in result.stdout
            )
        except:
            self.home_screen.notification_bar.bluetooth_status = False
    
    def add_notification(self, title, message, priority=0):
        self.home_screen.notification_bar.show_notification(f"{title}: {message}")
    
    def show_wifi_setup(self, instance):
        self.wifi_popup = WiFiSetupPopup(self)
        self.wifi_popup.open()
    
    def show_bluetooth_setup(self, instance):
        self.bluetooth_popup = BluetoothSetupPopup(self)
        self.bluetooth_popup.open()
    
    # App launch methods
    def launch_tv(self, instance):
        subprocess.Popen(["python3", "tv_app.py"])
    
    def launch_camera(self, instance):
        subprocess.Popen(["python3", "camera_app.py"])
    
    def launch_browser(self, instance):
        try:
            webbrowser.open('http://google.com')
        except:
            subprocess.Popen(["chromium-browser", "--touch-events", "--enable-pinch"])
    
    def launch_streaming(self, instance):
        subprocess.Popen(["python3", "streaming_hub.py"])
    
    def launch_file_manager(self, instance):
        subprocess.Popen(["pcmanfm"])
    
    def launch_retroarch(self, instance):
        subprocess.Popen(["retroarch"])
    
    def launch_apk_manager(self, instance):
        subprocess.Popen(["python3", "apk_manager.py"])
    
    def launch_update(self, instance):
        subprocess.Popen(["python3", "update_manager.py"])
    
    def launch_settings(self, instance):
        subprocess.Popen(["python3", "settings_app.py"])
    
    def show_power_menu(self, instance):
        content = BoxLayout(orientation='vertical', spacing=10)
        btn_shutdown = Button(text="Shutdown")
        btn_reboot = Button(text="Reboot")
        btn_suspend = Button(text="Suspend")
        btn_cancel = Button(text="Cancel")
        
        btn_shutdown.bind(on_press=lambda x: os.system("sudo shutdown -h now"))
        btn_reboot.bind(on_press=lambda x: os.system("sudo reboot"))
        btn_suspend.bind(on_press=lambda x: os.system("sudo systemctl suspend"))
        btn_cancel.bind(on_press=lambda x: x.parent.parent.parent.dismiss())
        
        content.add_widget(btn_shutdown)
        content.add_widget(btn_reboot)
        content.add_widget(btn_suspend)
        content.add_widget(btn_cancel)
        
        popup = Popup(title="Power Options", content=content, size_hint=(0.6, 0.4))
        popup.open()

if __name__ == "__main__":
    TabletLauncher().run()