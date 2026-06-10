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
          # bitwig-studio
          lm_sensors
          scrcpy
          # libwebcam
          sccache
          wget
          mold
          # rustc
          # rustfmt
          gparted
          # gimp

          # davinci-resolve-studio
          cargo
          go
          uv
          python314
          pnpm
          delta
          v4l-utils
          guvcview
          ffmpeg-full
          SDL2
          yasm
          nasm
          gawk
          bc
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
        environment.etc."lvm/lvm.conf".text = ''
          devices {
            allow_mixed_block_sizes = 1
          }
        '';

        programs = {
          coolercontrol.enable = true;
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
          _1password.enable = true;
          _1password-gui = {
            enable = true;
            polkitPolicyOwners = [ "vera" ];
          };
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
            settings = {
              PermitRootLogin = "no";
            };
          };
          pipewire.enable = true;
          avahi.enable = true;
        };
        # enabled in the niri flake aspect
        # security = { polkit.enable = true; };
      };

    provides.to-users.includes = with den.aspects; [
      amd
      gpu
      ipod
      crypto
      bitwig-studio
      windows-vst
      davinci
      keyboard
      varnam
    ];
  };
}
