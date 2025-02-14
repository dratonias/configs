#!/bin/bash
# A simple script to get a vanilla KDE Plasma Desktop on Void Linux
# Version 1.0.1, updated 14-12-2022
clear

bypass() {
  sudo -v
  while true;
  do
    sudo -n true
    sleep 45
    kill -0 "$$" || exit
  done 2>/dev/null &
}
echo "Welcome to a simple script to get a vanilla KDE Plasma Desktop on Void Linux."
read -p "Would you like to continue (y/n)? " installChoice

case "$installChoice" in
  # User wants to continue installation
  y|Y|yes|Yes|YES )

    read -p "Would you like to perform a system upgrade before continuing (y/n)? " upgradeChoice
    case "$upgradeChoice" in
      y/Y/yes/Yes/YES )
        echo "Upgrading system..."
        sudo xbps-install -Su
      ;;
      n/N/no/No/NO )
        echo "Skipping system upgrade."
      ;;
    esac

    echo "Installing multilib and non-free repos..."
      sudo xbps-install -y void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree

    echo "Preparing to install packages..."
      echo "Installing build essentials and kernel headers..."
        sudo xbps-install -y base-devel make cmake rust cargo rsync
      echo "Installing graphics drivers..."
        sudo xbps-install -y intel-video-accel mesa-intel-dri mesa-vulkan-intel vulkan-loader
      echo "Installing audio packages..."
        sudo xbps-install -y alsa-utils alsa-plugins-pulseaudio ffmpeg ffmpegthumbs pulseaudio pipewire
      echo "Installing desktop environment..."
        sudo xbps-install -y xorg kde5 kde5-baseapps xdg-user-dirs xdg-utils xtools
      echo "Installing additional applications..."
        sudo xbps-install -y neofetch grub-customizer qbittorrent
        # Code editor
        echo "Installing Neovim..."
        sudo xbps-install -y neovim
        #TODO: call neovim setup script??
        # Web browser
        echo "Installing Vivaldi..."
        sudo xbps-install -y vivaldi
        # Audio recording and streaming
        echo "Installing OBS Studio..."
        sudo xbps-install -y obs
        
    echo "Configuring system..."
      echo "Setting up services..."
        sudo sed -i "s/--noclear/--noclear\ --skip-login\ --login-options=$USER/g" /etc/sv/agetty-tty1/conf
    sudo rm -f /var/service/agetty-tty{3,4,5,6}
    sudo ln -s /etc/sv/dbus /var/service/
    # sudo ln -s /etc/sv/sddm /var/service/
    sudo ln -s /etc/sv/NetworkManager /var/service/

    echo "Starting services..."
    sudo sv up dbus
    # sudo sv up sddm
    sudo sv up NetworkManager 
    
    echo "All done! Please reboot for all changes to take effect."
  ;;

  # User does not want to continue installation.
  n|N|no|No|NO )
    echo "Thanks for trying, Goodbye!";;
esac
