#!/bin/bash

# Usage:
#   ./theme.sh         # Run full setup
#   ./theme.sh reset   # Reset to default theme settings

# --- Helper: Print current theme ---
print_current_theme() {
    echo "Current GTK theme: $(gsettings get org.gnome.desktop.interface gtk-theme)"
    echo "Current Shell theme: $(gsettings get org.gnome.shell.extensions.user-theme name)"
    echo "Current Icon theme: $(gsettings get org.gnome.desktop.interface icon-theme)"
}

# --- Theme Switch Function (Light Only) ---
set_light_theme() {
    gsettings set org.gnome.desktop.interface gtk-theme "transparent-Light"
    gsettings set org.gnome.shell.extensions.user-theme name "transparent-Light"
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Light"
    echo "Switched to light theme."
    print_current_theme
}

# --- Reset to Default Theme Function ---
reset_to_default() {
    echo "Resetting to default themes and settings..."
    
    # Reset GTK and icon themes
    gsettings reset org.gnome.desktop.interface gtk-theme
    gsettings reset org.gnome.shell.extensions.user-theme name
    gsettings reset org.gnome.desktop.interface icon-theme
    
    # Reset terminal settings
    profile_id=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]'" | awk '{print $1}')
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ use-transparent-background
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ background-transparency-percent
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ use-theme-colors
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ background-color
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ foreground-color
    gsettings reset org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ palette
    
    # Reset dock settings
    gsettings reset org.gnome.shell.extensions.dash-to-dock transparency-mode
    gsettings reset org.gnome.shell.extensions.dash-to-dock background-opacity
    gsettings reset org.gnome.shell.extensions.dash-to-dock dock-fixed

    # Reset focus on hover settings
    gsettings reset org.gnome.desktop.wm.preferences focus-mode
    gsettings reset org.gnome.desktop.wm.preferences auto-raise

    gnome-extensions disable dynamic-panel-transparency@rockon999.github.io
    gnome-extensions disable transparent-top-bar@zhanghai.me
    gnome-extensions disable system-monitor@gnome-shell-extensions.gcampax.github.com
    
    echo "Reset complete. All settings have been restored to default values."
    print_current_theme
}

# --- Warn if run as root ---
if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root or with sudo. Run as your normal user."
    exit 1
fi

# --- Handle command line arguments ---
if [[ "$1" == "reset" ]]; then
    reset_to_default
    exit 0
fi

# --- Preparation ---
mkdir -p tmp_files
cd tmp_files

# --- Transparent Terminal ---
profile_id=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]'" | awk '{print $1}')

# Set terminal appearance - dark gray background only
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ use-theme-colors false

# --- GNOME Dock Transparency ---
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.5
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false  # Auto-hide dock

# --- Install Essential Tools ---
sudo apt install -y gnome-tweaks gnome-shell-extensions git gtk2-engines-murrine gtk2-engines-pixbuf

# --- GTK Theme: Layan Transparent ---
git clone https://github.com/vinceliuice/Layan-gtk-theme.git
cd Layan-gtk-theme
./install.sh --name transparent
gnome-extensions enable user-theme@gnome-shell-extensions.gcampax.github.com
cd ..

# --- Icon Theme: Papirus (Android-like minimal icons) ---
sudo add-apt-repository -y ppa:papirus/papirus
sudo apt update
sudo apt install -y papirus-icon-theme

# Apply the light theme with new icons
set_light_theme

# --- Useful GNOME Extensions & Widgets ---
sudo apt install -y gnome-shell-extension-prefs
gnome-extensions enable dynamic-panel-transparency@rockon999.github.io
gnome-extensions enable transparent-top-bar@zhanghai.me
gnome-extensions enable system-monitor@gnome-shell-extensions.gcampax.github.com

# --- Window Focus on Hover Settings ---
gsettings set org.gnome.desktop.wm.preferences focus-mode 'sloppy'
gsettings set org.gnome.desktop.wm.preferences auto-raise false
gsettings set org.gnome.desktop.wm.preferences auto-raise-delay 500

# --- Configure Dark Transparent Terminal ---
profile_id=$(gsettings get org.gnome.Terminal.ProfilesList list | tr -d "[]'" | awk '{print $1}')
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ use-transparent-background true
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ background-transparency-percent 10
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ background-color 'rgb(50,50,50)'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:${profile_id}/ foreground-color 'rgb(255,255,255)'

# --- Cleanup ---
cd ..
rm -rf tmp_files
