{ den, ... }:
{
  den.aspects.ampulex = {
    den.aspects.work.includes = [ den.provides.primary-user ];
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

        environment.systemPackages = with pkgs; [
          lm_sensors
          scrcpy
          networkmanager
          sccache
          wayland
          wget

          # TODO: fix nvim building without these
          gcc
          gnumake
          # TODO: end

          mold
          cargo
          go
          uv
          python314
          delta
          v4l-utils
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
          chromium.enable = true;
          fzf = {
            fuzzyCompletion = true;
            # enable = true;
            # enableZshIntegration = true;
            # defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";
          };
          _1password.enable = true;
          _1password-gui = {
            enable = true;
            polkitPolicyOwners = [
              "vera"
              "work"
            ];
          };
        };

        services = {
          fwupd.enable = true;
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
      keyboard
    ];
  };
}
