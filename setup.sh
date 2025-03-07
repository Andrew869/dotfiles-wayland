#!/bin/bash

# Original script by SolDoesTech - https://www.youtube.com/@SolDoesTech

# Define the software that would be inbstalled 
#Need some prep work
prep_stage=(
    nwg-look
    qt5-wayland 
    qt5ct
    qt6-wayland 
    qt6ct
    qt5-svg
    qt5-quickcontrols2
    qt5-graphicaleffects
    gtk3
    polkit-gnome 
    jq
    brightnessctl
    playerctl
    pipewire
    wireplumber
    pipewire-audio
    pipewire-alsa
    pipewire-pulse
    pipewire-jack
    less
    htop
    base-devel
)

#software for nvidia GPU only
nvidia_stage=(
    linux-headers
    nvidia-dkms
    #lib32-nvidia-utils
    #nvidia-settings
    libva-nvidia-driver
)

mapfile -t install_stage < "pkgs.txt"

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"
INSTLOG="install.log"

######
# functions go here

# function that would show a progress bar to the user
show_progress() {
    while ps | grep $1 &> /dev/null;
    do
        echo -n "."
        sleep 2
    done
    echo -en "Done!\n"
    sleep 2
}

# function that will test for a package and if not found it will attempt to install it
install_software() {
    # First lets see if the package is there
    if yay -Q $1 &>> /dev/null ; then
        echo -e "$COK - $1 is already installed."
    else
        # no package found so installing
        echo -en "$CNT - Now installing $1 ."
        yay -S --noconfirm $1 &>> $INSTLOG &
        show_progress $!
        # test to make sure package installed
        if yay -Q $1 &>> /dev/null ; then
            echo -e "\e[1A\e[K$COK - $1 was installed."
        else
            # if this is hit then a package is missing, exit to review log
            echo -e "\e[1A\e[K$CER - $1 install had failed, please check the install.log"
            exit
        fi
    fi
}

# clear the screen
clear

# set some expectations for the user
echo -e "$CNT - You are about to execute a script that would attempt to setup Hyprland.
Please note that Hyprland is still in Beta."
sleep 1

# attempt to discover if this is a VM or not
echo -e "$CNT - Checking for Physical or VM..."
chassis=$(hostnamectl | grep Chassis)
echo -e "Using $chassis"
if [[ $chassis == *"vm"* ]]; then
    echo -e "$CWR - Please note that VMs are not fully supported and if you try to run this on
    a Virtual Machine there is a high chance this will fail."
    sleep 1
elif [[ $chassis == *"laptop"* ]];then
    prep_stage+=(brightnessctl)
fi

# let the user know that we will use sudo
echo -e "$CNT - This script will run some commands that require sudo. You will be prompted to enter your password.
If you are worried about entering your password then you may want to review the content of the script."
sleep 1

# give the user an option to exit out
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to continue with the install (y,n) ' CONTINST
if [[ $CONTINST == "Y" || $CONTINST == "y" ]]; then
    echo -e "$CNT - Setup starting..."
    sudo touch /tmp/dot_config.tmp
else
    echo -e "$CNT - This script will now exit, no changes were made to your system."
    exit
fi

# find the Nvidia GPU
if lspci -k | grep -A 2 -E "(VGA|3D)" | grep -iq nvidia; then
    ISNVIDIA=true
else
    ISNVIDIA=false
fi

### Disable wifi powersave mode ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to disable WiFi powersave? (y,n) ' WIFI
if [[ $WIFI == "Y" || $WIFI == "y" ]]; then
    LOC="/etc/NetworkManager/conf.d/wifi-powersave.conf"
    echo -e "$CNT - The following file has been created $LOC.\n"
    echo -e "[connection]\nwifi.powersave = 2" | sudo tee -a $LOC &>> $INSTLOG
    echo -en "$CNT - Restarting NetworkManager service, Please wait."
    sleep 2
    sudo systemctl restart NetworkManager &>> $INSTLOG
    
    #wait for services to restore (looking at you DNS)
    for i in {1..6} 
    do
        echo -n "."
        sleep 1
    done
    echo -en "Done!\n"
    sleep 2
    echo -e "\e[1A\e[K$COK - NetworkManager restart completed."
fi

#### Check for package manager ####
if [ ! -f /sbin/yay ]; then  
    echo -en "$CNT - Configuering yay."
    git clone https://aur.archlinux.org/yay.git &>> $INSTLOG
    cd yay
    makepkg -si --noconfirm &>> ../$INSTLOG &
    show_progress $!
    if [ -f /sbin/yay ]; then
        echo -e "\e[1A\e[K$COK - yay configured"
        cd ..
        
        # update the yay database
        echo -en "$CNT - Updating yay."
        yay -Suy --noconfirm &>> $INSTLOG &
        show_progress $!
        echo -e "\e[1A\e[K$COK - yay updated."
    else
        # if this is hit then a package is missing, exit to review log
        echo -e "\e[1A\e[K$CER - yay install failed, please check the install.log"
        exit
    fi
fi

### Install all of the above pacakges ####
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install the packages? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then

    # Prep Stage - Bunch of needed items
    echo -e "$CNT - Prep Stage - Installing needed components, this may take a while..."
    for SOFTWR in ${prep_stage[@]}; do
        install_software $SOFTWR 
    done

    # Setup Nvidia if it was found
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "$CNT - Nvidia GPU support setup stage, this may take a while..."
        for SOFTWR in ${nvidia_stage[@]}; do
            install_software $SOFTWR
        done
    
        # update config
        sudo sed -i 's/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
        echo -e "options nvidia_drm modeset=1 fbdev=1" | sudo tee -a /etc/modprobe.d/nvidia.conf &>> $INSTLOG
        #sudo mkinitcpio --config /etc/mkinitcpio.conf --generate /boot/initramfs-custom.img
        sudo mkinitcpio -P
    fi

    # Install the correct hyprland version
    echo -e "$CNT - Installing Hyprland, this may take a while..."
    install_software hyprland

    # Stage 1 - main components
    echo -e "$CNT - Installing main components, this may take a while..."
    for SOFTWR in ${install_stage[@]}; do
        install_software $SOFTWR
        # echo "installing $SOFTWR"
    done

    read -rep $'[\e[1;33mACTION\e[0m] - Would you like to install Bluetooth utilities? (y,n) ' INST
    if [[ $INST == "Y" || $INST == "y" ]]; then
        install_software bluez
        install_software bluez-utils
        install_software blueman

        # Start the bluetooth service
        echo -e "$CNT - Starting the Bluetooth Service..."
        sudo systemctl enable --now bluetooth.service &>> $INSTLOG
        sleep 2
    fi


    # Enable the sddm login manager service
    echo -e "$CNT - Enabling the SDDM Service..."
    sudo systemctl enable sddm &>> $INSTLOG
    sleep 2
    
    # Clean out other portals
    echo -e "$CNT - Cleaning out conflicting xdg portals..."
    yay -R --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-gtk &>> $INSTLOG
fi

### Copy Config Files ###
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to copy config files? (y,n) ' CFG
if [[ $CFG == "Y" || $CFG == "y" ]]; then
    echo -e "$CNT - Copying config files..."

    path="dot_config/"

    file_configs=($(ls --group-directories-first $path))

    for config in ${file_configs[@]} 
    do 
        configPath=~/.config/$config
        newConfigPath="$path$config"

        if [ -e "$configPath" ]; then 
            echo -e "$CAT - Config for $config located, backing up."
            mv $configPath $configPath-backup &>> $INSTLOG
            echo -e "$COK - Backed up $config to $configPath-backup."
        fi

        if [ -d "$newConfigPath" ];then
            cp -r "$newConfigPath" ~/.config/
        else
            cp "$newConfigPath" ~/.config/
        fi
    done
    
    # ranger icons
    mkdir -p ~/.config/ranger/plugins && git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons &>> $INSTLOG

    # add the Nvidia env file to the config (if needed)
    if [[ "$ISNVIDIA" == true ]]; then
        echo -e "\nsource = ~/.config/hypr/env_var_nvidia.conf" >> ~/.config/hypr/env.conf
    fi


    # Theme config

    # Copy the SDDM theme
    echo -e "$CNT - Setting up the login screen."
    sudo cp -R theme_config/candy /usr/share/sddm/themes/
    sudo chown -R $USER:$USER /usr/share/sddm/themes/candy
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[Theme]\nCurrent=candy" | sudo tee -a /etc/sddm.conf.d/10-theme.conf &>> $INSTLOG

    # Qt and GTK config
    
    gsettings set org.gnome.desktop.interface gtk-theme 'Orchis-Dark-Compact'
    gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dark'
    gsettings set org.gnome.desktop.interface cursor-theme 'Breeze_Snow'
    
    sudo sed -i 's/Inherits=Adwaita/Inherits=Breeze_Snow/' /usr/share/icons/default/index.theme
    cp -r theme_config/gtk-3.0 ~/.config/
    cp -r theme_config/xsettingsd ~/.config/
    cp -r theme_config/qt5ct ~/.config/
    cp -r theme_config/qt6ct ~/.config/

    cp theme_config/.gtkrc-2.0 ~/

    mkdir -p ~/.local/share/icons/default
    cp theme_config/index.theme ~/.local/share/icons/default/
fi

# zsh setup
read -rep $'[\e[1;33mACTION\e[0m] - Would you like to use zsh? (y,n) ' INST
if [[ $INST == "Y" || $INST == "y" ]]; then
    install_software zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" &> /dev/null

    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions &>> $INSTLOG
    git clone https://github.com/zsh-users/zsh-completions ~/.oh-my-zsh/custom/plugins/zsh-completions &>> $INSTLOG
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting &>> $INSTLOG

    cp zsh_config/.zshrc ~/.zshrc
    cp zsh_config/andrew.zsh-theme ~/.oh-my-zsh/themes/
    chsh -s $(which zsh)
fi

# Global Env vars
PROFILE_FILE="/etc/profile.d/00-custom-env.sh"

sudo bash -c "cat > $PROFILE_FILE" << EOF
    #!/bin/bash
    export EDITOR=nvim
    export VISUAL=nvim
EOF


### Script is done ###
echo -e "$CNT - Script had completed!"
if [[ "$ISNVIDIA" == true ]]; then 
    echo -e "$CAT - Since we attempted to setup an Nvidia GPU the script will now end and you should reboot.
    Please type 'reboot' at the prompt and hit Enter when ready."
    exit
fi

read -rep $'[\e[1;33mACTION\e[0m] - Would you like to start Hyprland now? (y,n) ' HYP
if [[ $HYP == "Y" || $HYP == "y" ]]; then
    exec sudo systemctl start sddm &>> $INSTLOG
else
    exit
fi
