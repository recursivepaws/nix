{ den, ... }:
{
  den.aspects.hericium = {
    den.aspects.vera.includes = [ den.provides.primary-user ];
    nixos =
      { pkgs, ... }:
      {
        networking.hostName = "hericium";
        boot.loader.grub = {
          enable = true;
          efiSupport = false;
          device = "/dev/nvme0n1";
        };
        boot.loader.efi.canTouchEfiVariables = true;
        boot.loader.efi.efiSysMountPoint = "/boot";

        environment.systemPackages = with pkgs; [
          nodejs_22
          pnpm
          gparted
        ];

        programs.obs-studio = {
          enable = true;
          enableVirtualCamera = true;
        };
      };

    provides.to-users.includes = with den.aspects; [
      amd
      ipod
      crypto
      bitwig-studio
      windows-vst
      davinci
      varnam
      gaming
    ];
  };
}
