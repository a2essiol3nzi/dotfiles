{ config, pkgs, zen-browser, hermes-agent, ... }:

let
  # Temporary packaging bridge: upstream's Nix wheel currently omits these
  # standalone modules although hermes_state.py imports them.
  hermesStateSupport = pkgs.python312Packages.buildPythonPackage {
    pname = "hermes-state-support";
    version = "0.0.0";
    pyproject = true;
    src = pkgs.runCommand "hermes-state-support-src" {} ''
      mkdir -p $out
      cp ${hermes-agent.outPath}/hermes_state_holders.py $out/
      cp ${hermes-agent.outPath}/hermes_state_registry.py $out/
      printf '%s\n' \
        '[build-system]' \
        'requires = ["setuptools"]' \
        'build-backend = "setuptools.build_meta"' \
        '[project]' \
        'name = "hermes-state-support"' \
        'version = "0.0.0"' \
        '[tool.setuptools]' \
        'py-modules = ["hermes_state_holders", "hermes_state_registry"]' \
        > $out/pyproject.toml
    '';
    build-system = [ pkgs.python312Packages.setuptools ];
  };
in
{
  home.username = "axel";
  home.homeDirectory = "/home/axel";
  home.stateVersion = "26.05";

  # ── Git ──────────────────────────────────────────────────────────────────────

  programs.git.enable = true;

  # ── Shell ────────────────────────────────────────────────────────────────────

  # programs.zsh = {
  #   enable = true;
  #   initContent = ''
  #     # Carica la configurazione portatile
  #     if [ -f ~/.zshrc.portable ]; then
  #       source ~/.zshrc.portable
  #     fi
  #   '';
  # };

  programs.zsh = {
    enable = true;
    completionInit = ""; # dice a Home Manager di non generare il suo compinit

    # ── History ────────────────────────────────────────────────────────────────
    history = {
      path = "$HOME/.config/zsh/.zsh_history";
      size = 10000;
      save = 10000;
      share = true;           # sharehistory
      ignoreDups = true;      # hist_ignore_all_dups
      ignoreSpace = true;     # hist_ignore_space
      append = true;          # appendhistory
    };

    # ── Alias ──────────────────────────────────────────────────────────────────
    shellAliases = {
      # NixOS
      nrs = "sudo nixos-rebuild switch --flake ~/Projects/Dotfiles/nixos-dotfiles#ZeNix";
      nrb = "sudo nixos-rebuild boot --flake ~/Projects/Dotfiles/nixos-dotfiles#ZeNix";
      nuf = "sudo nix flake update --flake ~/Projects/Dotfiles/nixos-dotfiles";
      ngc = "sudo nix-collect-garbage -d";

      # Navigazione
      ls  = "ls --color=auto";
      l   = "ls";
      ll  = "ls -lh";
      la  = "ls -lha";
      grep = "grep --color=auto";

      # Fastfetch
      ff       = "fastfetch -c ~/.config/fastfetch/screenfetch.jsonc";
      fullfetch = "fastfetch -c ~/.config/fastfetch/all.jsonc";

      # Kitty
      kicat  = "kitten icat";
      kifont = "kitty +list-fonts --full-name";
      ssh    = "kitty +kitten ssh";
    };

    # ── Completamenti e setopt ──────────────────────────────────────────────────
    initContent = ''
      # ZDOTDIR già impostato da Home Manager, ma history path dipende da esso
      # HISTFILE="$HOME/.config/zsh/.zsh_history" # VIENE GENERATO AUTOMATICAMENTE

      # Completamenti
      autoload -Uz compinit
      compinit -d "$HOME/.config/zsh/.zcompdump"
      if [[ -f "$HOME/.config/zsh/.zcompdump" && ! "$HOME/.config/zsh/.zcompdump.zwc" -nt "$HOME/.config/zsh/.zcompdump" ]]; then
        zcompile "$HOME/.config/zsh/.zcompdump"
      fi
      zstyle ':completion:*' menu select

      # ── Prompt Tokyo Night ───────────────────────────────────────────────────
      setopt PROMPT_SUBST
      autoload -Uz vcs_info
      precmd() { vcs_info }
      zstyle ':vcs_info:git:*' formats ' %F{203}(%b)%f'
      zstyle ':vcs_info:git:*' actionformats ' %F{203}(%b|%a)%f'
      zstyle ':vcs_info:*' check-for-changes true
      PROMPT='%F{111}%~''${vcs_info_msg_0_}%f
      %F{141}❯ %f'

      # ── Keybindings ──────────────────────────────────────────────────────────
      bindkey "^[[A" up-line-or-search
      bindkey "^[[B" down-line-or-search
      bindkey "^[[1;5C" forward-word
      bindkey "^[[1;5D" backward-word
      bindkey "^[[3;5~" delete-word
      bindkey "^H" backward-delete-word

      # ── Plugin (gestiti manualmente per compilazione bytecode .zwc) ──────────
      ZSH_PLUGINS_DIR="$HOME/.config/zsh/plugins"
      load_plugin() {
        local plugin_dir="$ZSH_PLUGINS_DIR/$1"
        local plugin_script="$plugin_dir/$2"
        if [[ -f "$plugin_script" ]]; then
          if [[ ! "$plugin_script.zwc" -nt "$plugin_script" ]]; then
            zcompile "$plugin_script"
          fi
          source "$plugin_script"
        fi
      }
      load_plugin "fast-syntax-highlighting" "fast-syntax-highlighting.plugin.zsh"
      load_plugin "zsh-autosuggestions" "zsh-autosuggestions.zsh"

      # ── GPG TTY (deve essere per-sessione, non in sessionVariables) ──────────
      # export GPG_TTY="$(tty)" # VIENE GENERATO AUTOMATICAMENTE
    '';
  };

  # usati solo durante l'installazione
  programs.bash = {
    enable = true;

    # # Avvia Sway automaticamente quando fai login sul TTY1
    # profileExtra = ''
    #   if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    #     exec sway
    #   fi
    # '';

    shellAliases = {
      nrs = "sudo nixos-rebuild switch --flake ~/Projects/Dotfiles/nixos-dotfiles#ZeNix";
      nrb = "sudo nixos-rebuild boot --flake ~/Projects/Dotfiles/nixos-dotfiles#ZeNix";
      ngc = "sudo nix-collect-garbage -d";

      l = "ls";
      ll = "ls -l";
      la = "ls -la";
    };
  };

  # -- Fzf ----------------------------------------------------------------------

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # -- Yazi----------------------------------------------------------------------

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── GPG ──────────────────────────────────────────────────────────────────────

  # Gestisce ~/.gnupg/gpg.conf (nessuna opzione extra per ora)
  programs.gpg.enable = true;

  # Gestisce ~/.gnupg/gpg-agent.conf e il servizio systemd --user gpg-agent.
  # - pinentry.package scrive il path ASSOLUTO dello store Nix in
  #   "pinentry-program"
  # - L'unit systemd viene rigenerata da Home Manager ad ogni rebuild
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    defaultCacheTtl = 600;     # tiene la passphrase in cache 10 min
    maxCacheTtl = 7200;        # massimo 2 ore prima di richiederla di nuovo
    enableSshSupport = false;  # true per usare la chiave GPG anche per SSH
  };

  # ── Variabili d'ambiente ─────────────────────────────────────────────

  home.sessionVariables = {
    NIXOS_OZONE_WL  = "1";           # abilita Wayland nativo per app Electron (es. VSCode)
    MOZ_ENABLE_WAYLAND = "1";        # forza Firefox/Zen su Wayland invece di XWayland
    QT_QPA_PLATFORM = "wayland";     # forza le app Qt su Wayland
    SDL_VIDEODRIVER = "wayland";     # forza SDL su Wayland (videogiochi ecc.)
    _JAVA_AWT_WM_NONREPARENTING = "1"; # fix per app Java (es. IntelliJ) in WM non-reparenting
    EDITOR = "hx";                   # imposta helix come editor di default
    SHELL = "${pkgs.zsh}/bin/zsh";   # imposta zsh come shell di default per la sessione
    XCURSOR_THEME = "Bibata-Modern-Ice";
    XCURSOR_SIZE = 20;             # applicazione corretta cursore
  };

  # ── Hermes Agent ─────────────────────────────────────────────────────────────

  home.activation.hermesEnv = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/.hermes
    if [ ! -f $HOME/.hermes/.env ]; then
      ${pkgs.pass}/bin/pass show openrouter/hermes-key > $HOME/.hermes/.env.tmp 2>/dev/null \
        && echo "OPENROUTER_API_KEY=$(cat $HOME/.hermes/.env.tmp)" > $HOME/.hermes/.env \
        && rm $HOME/.hermes/.env.tmp
    fi
  '';

  # ── Aggiunte Path ─────────────────────────────────────────────

  # home.sessionPath = [
  #   "${config.home.homeDirectory}/.local/bin"
  # ];

  # ── Tema e Aspetto ──────────────────────────────────────────────────────────

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  home.pointerCursor = {
    gtk.enable = true;
    sway.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;
  };

  # -- Software per utente -----------------------------------------------------

  home.packages = with pkgs; [
    # Browser
    zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Editor
    kitty
    helix
    pkgs.vscodium

    # Wayland ecosystem
    swaybg
    swaylock
    swayidle
    swayimg
    waybar
    niri
    bemenu
    grim
    slurp
    wl-clipboard

    # Utilità
    unzip
    zip
    wallust
    fastfetch
    btop
    gnupg
    pass
    pinentry-curses
    openssl
    lazygit
    wlr-randr
    thunderbird
    qalculate-gtk
    netcat-gnu

    # Produttività
    obsidian
    spotify
    typst
    pandoc

    # Programmazione generale
    (hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      postFixup = (old.postFixup or "") + ''
        for program in hermes hermes-agent hermes-acp; do
          wrapProgram "$out/bin/$program" \
            --prefix PYTHONPATH : "${hermesStateSupport}/${pkgs.python312.sitePackages}"
        done
      '';
    }))
    codex
    nil
    gcc
    gnumake
    cmake
    ninja
    cereal
    openmpi
    pkg-config
    bear
    python3
    pyright
    jdk
    jdt-language-server
    tinymist
    clang-tools
  ];
}
