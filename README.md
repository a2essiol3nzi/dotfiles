# Axel's Dotfiles

Welcome to my personal collection of configuration files for Arch Linux. This repository contains my custom "rice" and settings for various tools, ranging from Suckless utilities to modern Wayland compositors.

## 📸 Previews

Here are some snapshots of the setup:

<p align="center">
  <img src="images/setup-130326.png" alt="Latest Setup" width="800px">
</p>

<details>
  <summary>More Screenshots</summary>
  
  ### Previous Iterations
  ![Setup 03-07-26](images/setup-030726.png)
  ![Setup 23-01-26](images/setup-230126.png)
  ![Setup 04-01-26](images/setup-040126.png)
  ![Setup 27-12-25](images/setup-271225.png)
  ![Setup 24-11-25](images/setup-241125.png)
  ![Setup 12-10-25](images/setup-121025.png)
  ![Setup 01-10-25](images/setup-011025.png)
  ![DWM Rice](images/dwm-rice.png)
</details>

## 🛠 Tools & Software

This repository includes configurations for:

- **Window Managers**: `dwm`, `dwl`, `sway`, `niri`
- **Terminals**: `alacritty`, `kitty`, `foot`
- **Editors**: `helix`
- **Browsers**: `zen-browser`
- **Utilities**:
  - `zsh` (Primary shell)
  - `tmux` (Terminal multiplexer)
  - `tofi`, `bemenu`, `dmenu` (Launchers/Menus)
  - `waybar` (Status bar)
  - `slock` & `slstatus` (Suckless locking and status)
  - `wallust` & `pywal` (Color scheme generation)
  - `pcmanfm` (File manager)
  - `swaybg`, `swayidle`, `swaylock` (Wayland session management)
- **Others**: `fontconfig`, `fastfetch`, `brightnessctl`
- **Scripts**:
  - [`dotInstall.sh`](./dotInstall.sh) (Automated symlink installation)
  - [`compress_walls.sh`](./compress_walls.sh) (Wallpaper optimization)

## 🚀 Installation

These dotfiles are organized to be easily managed. 

- **Standard Apps**: Most configurations (like `kitty`, `helix`, `sway`) reside in their respective folders and are meant to be linked to `~/.config/`. You can use the included `./dotInstall.sh` script to automate this.
- **Suckless Tools**: Source code is provided for `dwm`, `dwl`, `dmenu`, etc. You should enter each directory and run `sudo make clean install` manually.

## Wallpapers!

I (finally) managed to compress my [wallpapers](wallpapers). So, enjoy!

---
*Stay Hungry.*
