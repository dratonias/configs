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

    # echo "Removing multilib and non-free repos..."
    #   sudo xbps-remove -R void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree

    echo "Preparing to remove packages..."
      echo "Removing build essentials and kernel headers..."
        sudo xbps-remove -R base-devel make cmake rust cargo rsync
      echo "Removing graphics drivers..."
        sudo xbps-remove -R intel-video-accel mesa-intel-dri mesa-vulkan-intel vulkan-loader
      echo "Removing audio packages..."
        sudo xbps-remove -R alsa-utils alsa-plugins-pulseaudio ffmpeg ffmpegthumbs pulseaudio pipewire
      echo "Removing desktop environment..."
        sudo xbps-remove -R xorg kde5 kde5-baseapps xdg-user-dirs xdg-utils xtools
      echo "Removing utilities and system tools..."
        sudo xbps-remove -R gvfs gvfs-mtp gzip ntp procps-ng udisks2 unzip zip ark wget curl plymouth bluez tlp tlp-rdw preload zstd
      echo "Removing additional applications..."
        sudo xbps-remove -R neofetch htop alacritty kvantum timeshift qt5-devel exa grub-customizer spectacle kcalc gwenview fbv ntfs-3g telegram-desktop hplip octoxbps qbittorrent
        # Edit the following list of additional applications or replace them with your own preferences
        # Code editor
        echo "Removing Text Editors..."
        sudo xbps-remove -R micro kate nano
        # PDF reader
        echo "Removing Evince..."
        sudo xbps-remove -R okular
        # Web browser
        echo "Removing Firefox..."
        sudo xbps-remove -R firefox
        # Screenshot utility
        # Image editor
        echo "Removing GIMP..."
        sudo xbps-remove -R gimp
        # Office suite
        echo "Removing LibreOffice..."
        sudo xbps-remove -R libreoffice
        # Audio and video player
        echo "Removing VLC..."
        sudo xbps-remove -R vlc
        # Audio recording and streaming
        echo "Removing OBS Studio..."
        sudo xbps-remove -R obs
        # File manager...atool is installed for the ranger_archives plugin to work properly
        echo "Removing Ranger..."
        sudo xbps-remove -R ranger atool
        # Remove ZSH and Oh My ZSH
        echo "Removing ZSH..."
        sudo xbps-remove -R zsh
        
    echo "Stopping services..."
    sudo sv down dbus
    sudo sv down sddm
    sudo sv down NetworkManager 

    echo "Configuring system..."
      # echo "Tearing down up services..."
      #   sudo sed -i "s/--noclear/--noclear\ --skip-login\ --login-options=$USER/g" /etc/sv/agetty-tty1/conf
      #   TODO: look at this manually
    sudo ln -s /etc/sv/agetty-tty3 /var/service/
    sudo ln -s /etc/sv/agetty-tty4 /var/service/
    sudo ln -s /etc/sv/agetty-tty5 /var/service/
    sudo ln -s /etc/sv/agetty-tty6 /var/service/
    sudo sv up agetty-tty3 agetty-tty4 agetty-tty5 agetty-tty6

    sudo rm /var/service/dbus /var/service/sddm /var/service/NetworkManager


    echo "All done! Please reboot for all changes to take effect."
  ;;

  # User does not want to continue installation.
  n|N|no|No|NO )
    echo "Thanks for trying, Goodbye!";;
esac
