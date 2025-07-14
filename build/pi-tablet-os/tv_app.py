#!/usr/bin/env python3
import os
import subprocess
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.togglebutton import ToggleButton
from kivy.uix.popup import Popup
from kivy.clock import Clock
import v4l2
import fcntl
import dvb

# Complete Station Database
STATIONS = {
    # --- US Networks ---
    "Fox News (Cable)": {
        "freq": "93900000",  # Typical cable frequency
        "type": "atsc",
        "channel": "45",
        "source": "cable"
    },
    "Fox News (OTA)": {  # Over-the-air where available
        "freq": "533000000",
        "type": "atsc",
        "channel": "28",
        "region": "US"
    },
    
    # --- UK Freeview ---
    "BBC One": {
        "freq": "554000000",
        "type": "dvb-t",
        "channel": "30",
        "region": "UK"
    },
    "BBC Two": {
        "freq": "562000000",
        "type": "dvb-t", 
        "channel": "31",
        "region": "UK"
    },
    
    # --- FM Radio ---
    "Froggy 104": {
        "freq": "104000000",
        "type": "fm",
        "sdr": True,
        "region": "US"
    },
    "BBC Radio 1": {
        "freq": "97700000",
        "type": "fm",
        "sdr": True,
        "region": "UK"
    }
}

class TvTuner:
    def __init__(self):
        self.process = None
        self.current_freq = None

    def tune(self, freq, station_type):
        """Universal tuning method for all station types"""
        self.stop()
        
        try:
            if station_type == "fm":
                self._tune_fm(freq)
            elif station_type in ["dvb-t", "atsc"]:
                self._tune_dtv(freq, station_type)
                
            return True
        except Exception as e:
            print(f"Tuning error: {e}")
            return False

    def _tune_fm(self, freq):
        """Tune FM radio with RTL-SDR"""
        cmd = (
            f"rtl_fm -f {freq} -M wbfm -s 200k -r 48k -l 0 -A fast | "
            f"ffmpeg -loglevel quiet -f s16le -ar 48k -ac 1 -i - "
            f"-f pulse \"Default Audio Device\""
        )
        self.process = subprocess.Popen(
            cmd,
            shell=True,
            preexec_fn=os.setsid
        )
        self.current_freq = freq

    def _tune_dtv(self, freq, std):
        """Tune digital TV (DVB-T/ATSC)"""
        if std == "dvb-t":
            params = {
                "frequency": int(freq),
                "inversion": dvb.frontend.INVERSION_AUTO,
                "bandwidth_hz": 8000000,
                "code_rate_HP": dvb.frontend.FEC_AUTO,
                "modulation": dvb.frontend.QAM_AUTO
            }
        else:  # ATSC
            params = {
                "frequency": int(freq),
                "modulation": dvb.frontend.VSB_8
            }
            
        adapter = dvb.frontend.Frontend(0)
        adapter.set_frontend(params)
        
        self.process = subprocess.Popen([
            "vlc",
            "dvb://",
            f"--dvb-frequency={freq}",
            "--dvb-bandwidth=8"
        ])
        self.current_freq = freq

    def stop(self):
        """Stop any ongoing playback"""
        if self.process:
            try:
                os.killpg(os.getpgid(self.process.pid), 15)
            except:
                self.process.terminate()
            self.process = None
        self.current_freq = None

class TvApp(App):
    def build(self):
        self.tuner = TvTuner()
        self.setup_ui()
        return self.layout

    def setup_ui(self):
        """Initialize the user interface"""
        self.layout = BoxLayout(orientation='vertical')
        
        # Header
        self.header = Label(
            text="Pi Tablet TV/Radio",
            size_hint=(1, 0.1),
            font_size='24sp'
        )
        self.layout.add_widget(self.header)
        
        # Station Grid
        self.station_grid = BoxLayout(
            orientation='vertical',
            size_hint=(1, 0.7),
            spacing=10,
            padding=10
        )
        self.create_station_buttons()
        self.layout.add_widget(self.station_grid)
        
        # Controls
        controls = BoxLayout(size_hint=(1, 0.2), spacing=10)
        controls.add_widget(Button(
            text="Full Channel Scan",
            on_press=self.run_full_scan
        ))
        controls.add_widget(Button(
            text="Stop Playback",
            on_press=self.stop_playback
        ))
        self.layout.add_widget(controls)

    def create_station_buttons(self):
        """Organize stations by region and type"""
        categories = {
            "US Television": [],
            "UK Television": [],
            "US Radio": [],
            "UK Radio": []
        }
        
        for name, info in STATIONS.items():
            if info["type"] in ["dvb-t", "atsc"]:
                if info.get("region") == "UK":
                    categories["UK Television"].append((name, info))
                else:
                    categories["US Television"].append((name, info))
            elif info["type"] == "fm":
                if info.get("region") == "UK":
                    categories["UK Radio"].append((name, info))
                else:
                    categories["US Radio"].append((name, info))
        
        # Create rows for each category
        for category, stations in categories.items():
            if not stations:
                continue
                
            row = BoxLayout(size_hint=(1, None), height=80)
            row.add_widget(Label(
                text=category,
                size_hint=(0.3, 1),
                halign="left"
            ))
            
            btn_row = BoxLayout(spacing=5)
            for name, info in stations:
                btn_text = f"{name}\n{int(info['freq'])/1e6}MHz" if info['type'] == 'fm' else name
                btn = ToggleButton(
                    text=btn_text,
                    group="stations",
                    on_press=lambda x, n=name, i=info: self.tune_station(n, i),
                    halign="center"
                )
                btn_row.add_widget(btn)
            
            row.add_widget(btn_row)
            self.station_grid.add_widget(row)

    def tune_station(self, name, info):
        """Handle station tuning with visual feedback"""
        self.stop_playback()
        
        try:
            if self.tuner.tune(info["freq"], info["type"]):
                self.header.text = f"Now Playing: {name}"
                if info["type"] == "fm":
                    self.header.text += f"\n{int(info['freq'])/1e6} MHz"
            else:
                self.header.text = f"Failed to tune {name}"
        except Exception as e:
            self.header.text = f"Error: {str(e)}"

    def stop_playback(self, instance=None):
        """Stop all playback"""
        self.tuner.stop()
        self.header.text = "Playback stopped"

    def run_full_scan(self, instance):
        """Comprehensive channel scanning"""
        content = BoxLayout(orientation='vertical')
        scan_status = Label(text="Preparing scan...", size_hint=(1, 0.9))
        content.add_widget(scan_status)
        
        popup = Popup(
            title="Channel Scan",
            content=content,
            size_hint=(0.9, 0.9)
        )
        
        def update_scan(dt):
            scan_status.text = "Scanning US ATSC channels...\n"
            try:
                result = subprocess.run(
                    ["scan", "/usr/share/dvb/atsc/us-ATSC-center-frequencies-8VSB"],
                    capture_output=True, text=True
                )
                scan_status.text += result.stdout
            except Exception as e:
                scan_status.text += f"ATSC scan failed: {e}\n"
            
            scan_status.text += "\nScanning UK DVB-T channels...\n"
            try:
                result = subprocess.run(
                    ["w_scan", "-c", "GB", "-x"],
                    capture_output=True, text=True
                )
                scan_status.text += result.stdout
            except Exception as e:
                scan_status.text += f"DVB-T scan failed: {e}\n"
            
            scan_status.text += "\nScanning FM band (88-108MHz)...\n"
            try:
                result = subprocess.run(
                    ["rtl_power", "-f", "88M:108M:50k", "-i", "1m"],
                    capture_output=True, text=True
                )
                scan_status.text += self.parse_fm_scan(result.stdout)
            except Exception as e:
                scan_status.text += f"FM scan failed: {e}\n"
        
        Clock.schedule_once(update_scan, 0.1)
        popup.open()

    def parse_fm_scan(self, data):
        """Convert raw FM scan data to readable format"""
        stations = []
        for line in data.split('\n'):
            if not line.strip():
                continue
            parts = line.split()
            freq = float(parts[0])/1e6
            power = float(parts[6])
            if power > -50:  # Strong signal
                stations.append(f"{freq:.1f} MHz (strong)")
            elif power > -70:  # Weak signal
                stations.append(f"{freq:.1f} MHz (weak)")
        
        return "Detected FM stations:\n" + "\n".join(stations) if stations else "No FM stations found"

if __name__ == "__main__":
    # Verify all required tools are installed
    required = ["vlc", "rtl_fm", "ffmpeg", "w_scan", "scan"]
    missing = [cmd for cmd in required if not shutil.which(cmd)]
    
    if missing:
        print(f"Missing required tools: {', '.join(missing)}")
        print("Install with:")
        print("sudo apt install vlc rtl-sdr ffmpeg w-scan dvb-apps")
        exit(1)
    
    # Check DVB device
    if not os.path.exists("/dev/dvb/adapter0/frontend0"):
        print("DVB device not found! Check TV Hat installation.")
        print("You may need to add to /boot/config.txt:")
        print("dtoverlay=dvb")
        exit(1)
    
    TvApp().run()