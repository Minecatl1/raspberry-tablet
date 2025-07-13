import os
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.button import Button
from kivy.uix.togglebutton import ToggleButton
from kivy.uix.slider import Slider
from kivy.uix.popup import Popup
from kivy.uix.label import Label
from kivy.clock import Clock
from picamera2 import Picamera2
from lib.notification_manager import NotificationManager
import time

class CameraApp(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.camera = None
        self.is_recording = False
        self.notification = NotificationManager()
        self.camera_config = {
            'resolution': (1920, 1080),
            'flash_mode': 'off',
            'exposure_mode': 'auto',
            'iso': 0,
            'rotation': 0
        }
        self.thermal_monitor = ThermalMonitor()

    def build(self):
        # Main layout
        layout = BoxLayout(orientation='vertical')
        
        # Camera preview
        self.preview = Image()
        layout.add_widget(self.preview)
        
        # Controls layout
        controls = BoxLayout(size_hint=(1, 0.2))
        
        # Capture button
        self.capture_btn = Button(text='Capture')
        self.capture_btn.bind(on_press=self.capture_image)
        controls.add_widget(self.capture_btn)
        
        # Video toggle
        self.video_btn = ToggleButton(text='Record Video')
        self.video_btn.bind(on_press=self.toggle_recording)
        controls.add_widget(self.video_btn)
        
        # Settings button
        settings_btn = Button(text='Settings')
        settings_btn.bind(on_press=self.show_settings)
        controls.add_widget(settings_btn)
        
        layout.add_widget(controls)
        
        # Initialize camera
        self.init_camera()
        
        return layout

    def init_camera(self):
        try:
            self.camera = Picamera2()
            self.camera.configure(self.camera.create_preview_configuration(
                main={"size": self.camera_config['resolution']}))
            self.camera.start()
            Clock.schedule_interval(self.update_preview, 1.0/30.0)
        except Exception as e:
            self.notification.show(
                "Camera Error", 
                f"Failed to initialize camera: {str(e)}",
                "error"
            )

    def update_preview(self, dt):
        if self.camera and not self.is_recording:
            frame = self.camera.capture_array()
            self.preview.texture = frame

    def capture_image(self, instance):
        if self.thermal_monitor.is_too_hot():
            self.notification.show(
                "Warning",
                "Camera disabled due to high temperature",
                "warning"
            )
            return
            
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        filename = f"/home/pi/Pictures/capture_{timestamp}.jpg"
        try:
            self.camera.capture_file(filename)
            self.notification.show(
                "Photo Captured", 
                f"Saved as {filename}",
                "info"
            )
        except Exception as e:
            self.notification.show(
                "Capture Error", 
                str(e),
                "error"
            )

    def toggle_recording(self, instance):
        if self.is_recording:
            self.stop_recording()
            instance.state = 'normal'
        else:
            self.start_recording()
            instance.state = 'down'

    def start_recording(self):
        if self.thermal_monitor.is_too_hot():
            self.notification.show(
                "Warning",
                "Recording disabled due to high temperature",
                "warning"
            )
            return
            
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        self.video_file = f"/home/pi/Videos/video_{timestamp}.h264"
        try:
            self.camera.start_recording(self.video_file)
            self.is_recording = True
            self.notification.show(
                "Recording Started", 
                f"Recording to {self.video_file}",
                "info"
            )
        except Exception as e:
            self.notification.show(
                "Recording Error", 
                str(e),
                "error"
            )

    def stop_recording(self):
        try:
            self.camera.stop_recording()
            self.is_recording = False
            self.notification.show(
                "Recording Stopped", 
                f"Video saved to {self.video_file}",
                "info"
            )
        except Exception as e:
            self.notification.show(
                "Recording Error", 
                str(e),
                "error"
            )

    def show_settings(self, instance):
        content = BoxLayout(orientation='vertical')
        
        # Resolution selector
        res_label = Label(text="Resolution:")
        content.add_widget(res_label)
        
        res_slider = Slider(min=0, max=2, step=1)
        res_slider.bind(value=self.set_resolution)
        content.add_widget(res_slider)
        
        # Flash mode
        flash_btn = ToggleButton(text='Flash')
        flash_btn.bind(state=self.set_flash_mode)
        content.add_widget(flash_btn)
        
        # Close button
        close_btn = Button(text='Close')
        popup = Popup(title='Camera Settings', content=content)
        close_btn.bind(on_press=popup.dismiss)
        content.add_widget(close_btn)
        
        popup.open()

    def set_resolution(self, instance, value):
        resolutions = [(1280, 720), (1920, 1080), (2592, 1944)]
        self.camera_config['resolution'] = resolutions[int(value)]
        self.camera.stop()
        self.init_camera()

    def set_flash_mode(self, instance, state):
        self.camera_config['flash_mode'] = 'on' if state == 'down' else 'off'
        # Implement actual flash control if hardware supports it

    def on_stop(self):
        if self.camera:
            if self.is_recording:
                self.stop_recording()
            self.camera.stop()
            self.camera.close()