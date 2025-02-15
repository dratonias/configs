#!/bin/bash
# A simple script to get a vanilla KDE Plasma Desktop on Void Linux
# Version 1.0.1, updated 14-12-2022
clear

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
      sudo xbps-install -Sy void-repo-multilib void-repo-multilib-nonfree void-repo-nonfree

    echo "Preparing to install packages..."
      echo "Installing firmware..."
        sudo xbps-install -Sy linux-firmware linux-firmware-amd mesa-dri
      # echo "Installing audio packages..."
        # sudo xbps-install -Sy alsa-utils alsa-plugins-pulseaudio ffmpeg ffmpegthumbs pulseaudio pipewire
      echo "Installing desktop environment..."
        sudo xbps-install -Sy kde-plasma NetworkManager
        # sudo xbps-install -Sy xorg xdg-user-dirs xdg-utils 
      echo "Installing additional applications..."
        sudo xbps-install -Sy neofetch grub-customizer qbittorrent
        # Code editor
      echo "Installing Neovim..."
      sudo xbps-install -Sy zig neovim
      #TODO: call neovim setup script??
      # Audio recording and streaming
      echo "Installing OBS Studio..."
      sudo xbps-install -Sy obs
      #flatpack
      echo "Installing Flatpaks..."
      sudo xbps-install -Sy flatpak
      sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      flatpak install flathub com.vivaldi.Vivaldi
      flatpak install flathub com.spotify.Client


    echo "Configuring system..."
    echo "Setting up services..."
    #sudo sed -i "s/--noclear/--noclear\ --skip-login\ --login-options=$USER/g" /etc/sv/agetty-tty1/conf
    #sudo rm -f /var/service/agetty-tty{3,4,5,6}
    sudo ln -s /etc/sv/dbus /var/service/
    sudo ln -s /etc/sv/sddm /var/service/
    sudo ln -s /etc/sv/NetworkManager /var/service/

    echo "Starting services..."
    sudo sv up dbus
    sudo sv up sddm
    sudo sv up NetworkManager 
    
    echo "All done! Please reboot for all changes to take effect."
  ;;

  # User does not want to continue installation.
  n|N|no|No|NO )
    echo "Thanks for trying, Goodbye!";;
esac
