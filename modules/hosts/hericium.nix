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

        services = {
          # BT headphones: A2DP output only, no HFP/HSP, no profile autoswitch.
          # Stops playback falling back to mono HFP "mic mode".
          # Headset mic unusable as a result; StreamCam is the input anyway.
          pipewire.wireplumber.extraConfig."51-bluez-headphones" = {
            "wireplumber.settings" = {
              "bluetooth.autoswitch-to-headset-profile" = false;
            };
            "monitor.bluez.properties" = {
              "bluez5.roles" = [ "a2dp_source" ];
              "bluez5.enable-sbc-xq" = true;
            };
          };

          # Deauthorize flaky Intel radio (see modules/default/bluetooth.nix).
          # BlueZ then only sees the external Realtek dongle.
          # hericium-only: amanita needs the Intel radio. No dongle = no BT.
          udev.extraRules = ''
            ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", ATTR{idProduct}=="0aa7", ATTR{authorized}="0"
          '';
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
