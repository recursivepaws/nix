# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, lib, config, pkgs, ... }: {
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

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
  users.users.vera = {
    isNormalUser = true;
    description = "Vera Gonzalez";
    extraGroups = [ "networkmanager" "wheel" ];
    ##packages = with pkgs; [ chezmoi cargo pnpm kitty fuzzel ];
    openssh.authorizedKeys.keys = [
      # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    unzip
    kitty
    zsh
    git
    gh
    fzf
    ripgrep
    fd
    clang
    mold
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
    lazygit
    delta
    xwayland-satellite
    spotify
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  programs.firefox.enable = true;
  programs.niri.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = { PermitRootLogin = "no"; };
  };
  services.blueman.enable = true;
  services.pipewire.enable = true;

  # nix = {
  #   package = pkgs.nixVersions.stable;
  #   extraOptions = ''
  #     experimental-features = nix-command flakes
  #   '';
  # };

  nix = let flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    channel.enable = false;

    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
