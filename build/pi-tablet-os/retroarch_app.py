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