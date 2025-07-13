import os
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from lib.notification_manager import NotificationManager

class StreamingServiceButton(Button):
    pass

class StreamingHub(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.notification = NotificationManager()
        self.drm_supported = self.check_drm_support()
        self.services = [
            {'name': 'Netflix', 'package': 'com.netflix.ninja'},
            {'name': 'YouTube', 'package': 'com.google.android.youtube'},
            {'name': 'Disney+', 'package': 'com.disney.disneyplus'},
            {'name': 'Prime Video', 'package': 'com.amazon.amazonvideo'},
            {'name': 'Browser Streaming', 'command': 'chromium-browser --widevine-cdm-path=/usr/lib/chromium-widevine'}
        ]

    def build(self):
        layout = BoxLayout(orientation='vertical')
        
        # Title
        title = Label(text='Streaming Hub', size_hint=(1, 0.1))
        layout.add_widget(title)
        
        # Services grid
        scroll = ScrollView()
        grid = GridLayout(cols=2, spacing=10, size_hint_y=None)
        grid.bind(minimum_height=grid.setter('height'))
        
        for service in self.services:
            btn = StreamingServiceButton(text=service['name'])
            btn.service = service
            btn.bind(on_press=self.launch_service)
            grid.add_widget(btn)
        
        scroll.add_widget(grid)
        layout.add_widget(scroll)
        
        # DRM status
        drm_status = "Supported" if self.drm_supported else "Not Supported"
        status_label = Label(text=f'Widevine DRM: {drm_status}', size_hint=(1, 0.1))
        layout.add_widget(status_label)
        
        return layout

    def check_drm_support(self):
        try:
            # Check if Widevine is installed
            return os.path.exists('/usr/lib/chromium-widevine')
        except Exception as e:
            self.notification.show(
                "DRM Check Error",
                str(e),
                "error"
            )
            return False

    def launch_service(self, instance):
        service = instance.service
        
        if 'package' in service:
            self.launch_android_app(service['package'])
        elif 'command' in service:
            self.launch_browser_stream(service['command'])

    def launch_android_app(self, package):
        try:
            # Launch through Waydroid
            subprocess.Popen(['waydroid', 'app', 'launch', package])
            self.notification.show(
                "Streaming Hub",
                f"Launching {package}",
                "info"
            )
        except Exception as e:
            self.notification.show(
                "Launch Error",
                str(e),
                "error"
            )

    def launch_browser_stream(self, command):
        try:
            subprocess.Popen(command.split())
            self.notification.show(
                "Streaming Hub",
                "Launching browser player",
                "info"
            )
        except Exception as e:
            self.notification.show(
                "Browser Error",
                str(e),
                "error"
            )