{ lib, den, ... }: {
  den.default.nixos.system.stateVersion = "25.11";
  den.default.homeManager.home.stateVersion = "25.11";

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # host<->user provides
  den.ctx.user.includes = [ den._.mutual-provider ];

  # Allow unfree packages
  den.default.nixos = {
    # Set your time zone.
    time.timeZone = "America/New_York";

    nix.settings.trusted-users = [ "root" "@wheel" ];

    nix.settings.experimental-features =
      [ "nix-command" "flakes" "recursive-nix" ];
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
  };
  den.default.homeManager = { nixpkgs.config.allowUnfree = true; };
}
