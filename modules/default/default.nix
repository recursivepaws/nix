{
  lib,
  den,
  ...
}:
let
  stateVersion = "25.11";
in
{
  #den.default.nixos.system.stateVersion = "25.11";
  # den.default.homeManager.home.stateVersion = "25.11";

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # host<->user provides
  den.schema.user.includes = [ den._.mutual-provider ];

  # Default aspects
  den.default.includes = with den.aspects; [
    music
    beets
    spotify
    niri
    noctalia
    file-manager
    terminal
    browser
    claude
    gimp
    keyboard
    # software-repos
  ];

  # Allow unfree packages
  den.default.nixos =
    { pkgs, host, ... }:
    {
      system.stateVersion = stateVersion;

      # Wipe /tmp on every boot so stale files can't accumulate.
      boot.tmp.cleanOnBoot = true;

      # Back up pre-existing dotfiles instead of aborting the whole
      # home-manager activation when one collides with a managed file.
      home-manager.backupFileExtension = "hm-backup";

      # Set your time zone.
      time.timeZone = "America/New_York";

      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
        "recursive-nix"
      ];

      # Select internationalisation properties.
      i18n.defaultLocale = "en_US.UTF-8";

      # Do i need this?
      # i18n.extraLocaleSettings = {
      #   LC_ADDRESS = "en_US.UTF-8";
      #   LC_IDENTIFICATION = "en_US.UTF-8";
      #   LC_MEASUREMENT = "en_US.UTF-8";
      #   LC_MONETARY = "en_US.UTF-8";
      #   LC_NAME = "en_US.UTF-8";
      #   LC_NUMERIC = "en_US.UTF-8";
      #   LC_PAPER = "en_US.UTF-8";
      #   LC_TELEPHONE = "en_US.UTF-8";
      #   LC_TIME = "en_US.UTF-8";
      # };

      nixpkgs.config.allowUnfree = true;

      # Essential system packages
      environment.systemPackages = with pkgs; [
        eza
        bat
        zoxide
        tree
        wayland
        networkmanager
        unzip
        fzf
        ripgrep
        fd
        clang
        htop

        # Dev toolchain + media tools shared by all hosts
        # TODO: fix nvim building without these
        gcc
        gnumake
        # TODO: end
        cargo
        go
        uv
        python314
        mold
        sccache
        clang-tools
        delta
        gawk
        bc
        wget
        lm_sensors
        scrcpy
        xprop
        v4l-utils
        guvcview
        ffmpeg-full
        SDL2
        yasm
        nasm
      ];

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GTK_USE_PORTAL = "1";
      };
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
        "/share/gtksourceview-4"
      ];

      services = {
        openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
          };
        };
        pipewire.enable = true;
      };

      # Prevent OOM freezes
      services.earlyoom = {
        enable = true;
        freeMemThreshold = 5;
        freeSwapThreshold = 10;
        enableNotifications = true;
      };

      # Compressed swap in RAM
      zramSwap = {
        enable = true;
        algorithm = "zstd";
      };

      programs = {
        coolercontrol.enable = true;
        fzf.fuzzyCompletion = true;
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = builtins.attrNames host.users;
        };
        nix-ld.enable = true;
        lazygit.enable = true;
        localsend.enable = true;
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-gnome3;
        };
        zsh = {
          enable = true;
          ohMyZsh = {
            enable = true;
            plugins = [
              "git"
              "fzf"
              "history"
            ];
          };
          # fzf-tab: fzf-driven completion menu (needs to load after oh-my-zsh's compinit)
          interactiveShellInit = lib.mkAfter ''
            source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
            zstyle ':completion:*' menu no
            zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath'
            zstyle ':fzf-tab:*' switch-group ',' '.'
          '';
        };
        starship.enable = true;
        # _1password.enable = true;
        # _1password-gui = {
        #   enable = true;
        #   polkitPolicyOwners = [
        #     user.userName
        #   ];
        # };
        dconf.enable = true;
      };

    };

  den.default.homeManager =
    { pkgs, config, ... }:
    {
      home.stateVersion = stateVersion;
      nixpkgs.config.allowUnfree = true;

      xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";

      # Bugfix for the overloaded pnpm not being able to find the right spot
      xdg.configFile."pnpm/config.yaml".text = ''
        storeDir: ${config.home.homeDirectory}/.local/share/pnpm/store
      '';

      home.file."${config.xdg.configHome}/starship.toml".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/EdenEast/nightfox.nvim/refs/heads/main/extra/carbonfox/starship.toml";
        hash = "sha256-NneOWmWRhL5sgP/qFSSeVhf41W+waiadwz+KXL7s04s=";
      };

      systemd.user.startServices = "sd-switch";

      programs = {
        home-manager.enable = true;
        zsh = {
          dotDir = config.home.homeDirectory;
        };
      };

      # Packages I consider essential for all users on all systems
      home.packages = with pkgs; [
        eog
        cameractrls
        cameractrls-gtk4
        wl-clipboard
        baobab
        gnome-disk-utility
        vlc
        popsicle
      ];
    };
}
