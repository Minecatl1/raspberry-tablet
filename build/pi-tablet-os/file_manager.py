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
            ("DEBs", "~/debs"),
            ("EXEs", "~/exes"),
            ("Documents", "~/Documents")
        ]
        
        for name, path in dirs:
            btn = Button(text=name, size_hint_x=0.2)
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
        if not os.path.exists(expanded_path):
            try:
                os.makedirs(expanded_path)
            except OSError as e:
                self.show_error("Error", f"Could not create directory: {e}")
                return
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
        if not self.selected_file:
            return
            
        file_ext = os.path.splitext(self.selected_file)[1].lower()
        
        try:
            if file_ext == '.apk':
                # Install APK using adb
                result = subprocess.run(['adb', 'install', '-r', self.selected_file], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    self.show_error("Success", "APK installed successfully!")
                else:
                    self.show_error("Error", f"APK installation failed:\n{result.stderr}")
            
            elif file_ext == '.deb':
                # Install DEB package
                result = subprocess.run(['sudo', 'dpkg', '-i', self.selected_file], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    # Fix dependencies
                    subprocess.run(['sudo', 'apt-get', 'install', '-f'], 
                                 capture_output=True, text=True)
                    self.show_error("Success", "DEB package installed successfully!")
                else:
                    self.show_error("Error", f"DEB installation failed:\n{result.stderr}")
            
            elif file_ext == '.exe':
                # Try to run EXE with Wine
                result = subprocess.run(['wine', self.selected_file], 
                                      capture_output=True, text=True)
                if result.returncode == 0:
                    self.show_error("Success", "EXE executed successfully with Wine!")
                else:
                    self.show_error("Error", f"EXE execution failed:\n{result.stderr}")
            
            else:
                self.show_error("Error", "Unsupported file type for installation")
                
        except Exception as e:
            self.show_error("Error", f"Installation failed: {str(e)}")
    
    def delete_file(self, instance):
        if not self.selected_file:
            return
            
        # Create confirmation popup
        content = BoxLayout(orientation='vertical')
        message = Label(text=f"Delete {os.path.basename(self.selected_file)}?")
        btn_layout = BoxLayout(size_hint_y=0.3)
        
        yes_btn = Button(text="Yes")
        no_btn = Button(text="No")
        
        popup = Popup(title="Confirm Delete", content=content, size_hint=(0.7, 0.4))
        
        def confirm_delete(instance):
            try:
                if os.path.isdir(self.selected_file):
                    shutil.rmtree(self.selected_file)
                else:
                    os.remove(self.selected_file)
                self.file_chooser._update_files()  # Refresh file list
                popup.dismiss()
            except Exception as e:
                self.show_error("Error", f"Could not delete: {str(e)}")
        
        yes_btn.bind(on_press=confirm_delete)
        no_btn.bind(on_press=popup.dismiss)
        
        btn_layout.add_widget(yes_btn)
        btn_layout.add_widget(no_btn)
        
        content.add_widget(message)
        content.add_widget(btn_layout)
        
        popup.open()
    
    def show_error(self, title, message):
        content = Label(text=message)
        popup = Popup(title=title, content=content, size_hint=(0.7, 0.4))
        popup.open()

if __name__ == '__main__':
    FileManagerApp().run()