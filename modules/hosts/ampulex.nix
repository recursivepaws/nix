{ den, ... }:
{
  den.aspects.ampulex = {
    den.aspects.vera.includes = [ den.provides.primary-user ];
    includes = [ den.aspects.audio-fix ];

    nixos =
      { pkgs, ... }:
      {
        networking.hostName = "ampulex";
        boot.loader.grub = {
          enable = true;
          efiSupport = true;
          device = "nodev";
        };
        boot.loader.systemd-boot.enable = false;
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.efi.efiSysMountPoint = "/boot";

        programs.chromium.enable = true;

        services.fwupd.enable = true;
        # enabled in the niri flake aspect
        # security = { polkit.enable = true; };
      };

    provides.to-users.includes = with den.aspects; [
      amd
      crypto
      davinci
      varnam
      gaming
    ];
  };
}
