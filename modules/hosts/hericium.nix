{ den, ... }: {
  den.aspects.hericium = {
    nixos = { pkgs, ... }: {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      environment.systemPackages = with pkgs; [
        claude-code
        nixfmt-rfc-style
        figma-linux
        lm_sensors
        blender
        anki
        scrcpy
        #neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
        networkmanager
        # libwebcam
        ragenix
        sccache
        wayland
        wget
        unzip
        gh
        fzf
        ripgrep
        fd
        clang
        mold
        # rustc
        # rustfmt
        gparted
        gimp

        # davinci-resolve-studio
        tor-browser
        cargo
        go
        uv
        python314
        lua5_1
        luarocks
        stylua
        pnpm
        tree-sitter
        nodejs_22
        delta
        xwayland-satellite
        v4l-utils
        lua-language-server
        eza
        bat
        zoxide
        guvcview
        ffmpeg-full
        SDL2
        yasm
        nasm
        tree
        gawk
        bc
        htop
        xprop
        clang-tools
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

      programs = {
        coolercontrol.enable = true;
        localsend.enable = true;
        chromium.enable = true;
        nix-ld.enable = true;
        lazygit.enable = true;
        neovim = {
          enable = true;
          defaultEditor = true;
        };
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-gnome3;
        };
        zsh = {
          enable = true;
          ohMyZsh = {
            enable = true;
            plugins = [ "git" "fzf" "history" ];
          };
        };
        obs-studio = {
          enable = true;
          enableVirtualCamera = true;
        };
        fzf = {
          fuzzyCompletion = true;

          # enable = true;
          # enableZshIntegration = true;
          # defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
        };
        starship.enable = true;
        _1password.enable = true;
        _1password-gui = {
          enable = true;
          polkitPolicyOwners = [ "vera" ];
        };
        dconf.enable = true;
        steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };
      };

      services = {
        openssh = {
          enable = true;
          settings = { PermitRootLogin = "no"; };
        };
        pipewire.enable = true;
        avahi.enable = true;
        trezord.enable = true;
        tor = {
          enable = true;
          openFirewall = true;
        };
      };
      # enabled in the niri flake aspect
      # security = { polkit.enable = true; };
    };

    provides.to-users.includes = with den.aspects; [
      amd
      gpu
      niri
      noctalia
      file-manager
      terminal
      ipod
      browser
    ];

    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };
}
