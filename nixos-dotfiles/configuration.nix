{ config, lib, pkgs, zen-browser, ... }:

let
  connectTunnel = pkgs.callPackage ./connect-tunnel.nix { };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.enable = true;
  # Tiene solo le ultime 10 generazioni nel boot menu
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # Kernel recente, utile per hardware moderno e Wayland
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Moduli necessari in initrd per aprire LUKS e montare btrfs prima del boot
  boot.initrd.kernelModules = [ "btrfs" ];

  # Dice all'initrd come sbloccare la partizione cifrata
  # "cryptroot" è il nome che abbiamo dato in cryptsetup open
  boot.initrd.luks.devices."cryptroot" = {
    allowDiscards = true;                     # abilita TRIM attraverso LUKS per l'SSD
    preLVM = true;
  };

  # Servizio systemd per impostare la soglia all'avvio
  systemd.services.battery-charge-threshold = {
    description = "Set battery charge threshold to 80%";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ]; # wantedBy richiede una lista
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold || true'";
    };
  };

  # Regola udev per maggiore sicurezza
  # Se il modulo della batteria viene caricato in ritardo, udev attiverà il servizio.
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="BAT0", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}+="battery-charge-threshold.service"
  '';

  # Riapplica la soglia dopo la sospensione (Resume)
  powerManagement.resumeCommands = ''
    echo 80 > /sys/class/power_supply/BAT0/charge_control_end_threshold || true
  '';
  
  # ── Rete ────────────────────────────────────────────────────────────────────

  services.openssh.enable = true;
  networking.hostName = "ZeNix";
  networking.networkmanager.enable = true;
  programs.nm-applet.enable = true;
  networking.firewall.enable = true;

  # ── Localizzazione ──────────────────────────────────────────────────────────

  time.timeZone = "Europe/Rome";

  i18n.defaultLocale = "it_IT.UTF-8";
  console.keyMap = "it";

  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };

  # ── zram Swap ───────────────────────────────────────────────────────────────

  # Swap in RAM compressa con zstd — nessuna partizione swap necessaria
  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  # ── Display Manager e Wayland ───────────────────────────────────────────────

  # greetd è un display manager minimale
  # tuigreet è il suo frontend testuale 
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''
          ${pkgs.tuigreet}/bin/tuigreet \
            --time \
            --sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions
        '';
        user = "greeter";
      };
    };
  };
  # Sway come window manager Wayland
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;  # compatibilità temi GTK in Wayland
  };

  programs.niri.enable = true;

  # XDG portals: necessari per screen sharing, file picker, ecc. in Wayland
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Audio ────────────────────────────────────────────────────────────────────

  # Pipewire è lo standard moderno per audio in Wayland
  security.rtkit.enable = true;  # permette a pipewire di ottenere priorità realtime
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;  # emulazione PulseAudio per compatibilità
  };

  # -- Bluetooth ----------------------------------------------------------------

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.blueman.enable = true;

  # ── Sicurezza ────────────────────────────────────────────────────────────────

  # Polkit gestisce le autorizzazioni privilegiate in ambienti senza DE
  # Necessario per molte operazioni in Wayland (mount, poweroff, ecc.)
  security.polkit.enable = true;

  # Il client Java esegue questo solo binario privilegiato per creare il tunnel.
  security.wrappers.AvConnect = {
    source = "${connectTunnel}/libexec/AvConnect.bin";
    owner = "root";
    group = "root";
    capabilities = "cap_net_admin,cap_dac_override+ep";
  };

  # Il client upstream cerca questi percorsi assoluti; sono link della generazione
  # NixOS corrente, non file installati in /usr/local.
  environment.pathsToLink = [ "/libexec" ];

  # ── Utente ──────────────────────────────────────────────────────────────────

  programs.zsh.enable = true;

  users.users.axel = {
    isNormalUser = true;
    extraGroups = [
      "wheel"         # sudo
      "video"         # accesso GPU, necessario per Wayland/Sway
      "audio"         # accesso audio
      "networkmanager" # gestione rete senza sudo
      "input"         # accesso dispositivi input, utile per alcuni tool Wayland
    ];
    shell = pkgs.zsh;
  };

  # ── Pacchetti di sistema ─────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    tree
    btrfs-progs
    wayland
    xwayland
    xwayland-satellite
    networkmanagerapplet # Fornisce nm-connection-editor
    blueman              # Fornisce blueman-manager
    adwaita-icon-theme   # Tema di icone per la systray
    upower
    nftables
    discord-ptb
    connectTunnel
  ];

  services.upower.enable = true;

  # ── Font ─────────────────────────────────────────────────────────────────────

  fonts = {
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-mono
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
      };
    };
  };

  # ── Nix settings ─────────────────────────────────────────────────────────────

  nixpkgs.config.allowUnfree = true; # permette installazione di sw non free

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Garbage collection automatica settimanale
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "26.05";
}
