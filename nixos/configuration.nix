{ inputs, config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./file-manager.nix
    # ./stylix.nix
    ./fonts.nix
    ./age.nix
    ./network.nix
    ./niri.nix
    ./noctalia.nix
    ./gpu.nix
    ./amd.nix
    ./davinci.nix
    ./ipod.nix
    ./camera.nix
    ./flatpak.nix
    ./webcam.nix
    # ./v4l2loopback.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.agenix.nixosModules.default
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelModules = [ "nct6775" ];

  boot.initrd.luks.devices."luks-ed949a4c-1c52-4ac8-91cf-00a3d5c8b922".device =
    "/dev/disk/by-uuid/ed949a4c-1c52-4ac8-91cf-00a3d5c8b922";
  networking.hostName = "NyaNix"; # Define your hostname.

  boot.loader.systemd-boot.extraEntries = {
    "arch.conf" = ''
      title Arch Linux
      linux /vmlinuz-arch
      initrd /amd-ucode.img
      initrd /initramfs-arch.img
      options root=UUID=49e09db5-a4ba-4790-b6e3-79fc890625dd rw
    '';
    "arch-fallback.conf" = ''
      title Arch Linux (Fallback)
      linux /vmlinuz-arch
      initrd /amd-ucode.img
      initrd /initramfs-arch-fallback.img
      options root=UUID=49e09db5-a4ba-4790-b6e3-79fc890625dd rw
    '';
  };

  # boot.kernelPatches = [{
  #   name = "webcam-fix";
  #   patch = ./webcam-fix.patch;
  # }];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  #  services.xserver.xkb = {
  #   layout = "us";
  #   variant = "";
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.

  users.defaultUserShell = pkgs.zsh;
  users.users.vera = {
    isNormalUser = true;
    description = "Vera Gonzalez";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    ##packages = with pkgs; [ chezmoi cargo pnpm kitty fuzzel ];
    # openssh.authorizedKeys.keys = [
    #   # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    # ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
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
    # sdl2-compat
    # sdl3
    #
    tree

    gawk
    bc

    htop
    xprop
    clang-tools
    (callPackage ./lotion.nix { })
  ];

  environment.etc = {
    "1password/custom_allowed_browsers" = {
      text = ''
        zen
      '';
      mode = "0755";
    };
  };

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
    adb.enable = true;
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

  nixpkgs.config.permittedInsecurePackages = [ "qtwebengine-5.15.19" ];

  # Make sure these are also enabled
  services.dbus.enable = true;

  # If using a DE without polkit, you may need:
  security.polkit.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = { PermitRootLogin = "no"; };
  };
  services.pipewire.enable = true;
  services.avahi.enable = true;
  services.trezord.enable = true;
  services.tor = {
    enable = true;
    openFirewall = true;
  };
  # services.blueman.enable = true;

  # xdg.autostart.enable = true;

  # services.uvcvideo.dynctrl.enable = true;

  # nix = {
  #   package = pkgs.nixVersions.stable;
  #   extraOptions = ''
  #     experimental-features = nix-command flakes
  #   '';
  # };

  nix.package = pkgs.nix;
  nix.settings.experimental-features =
    [ "nix-command" "flakes" "recursive-nix" ];
  nix.channel.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
